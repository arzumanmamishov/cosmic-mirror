import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/core/network/app_locale.dart';
import 'package:cosmic_mirror/features/auth/data/auth_storage.dart';
import 'package:cosmic_mirror/features/auth/data/models/auth_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Global handle to the auth storage. The interceptor and any out-of-band
/// caller (e.g. logout) hit the same secure keychain without threading a
/// reference through every service.
final AuthStorage authStorage = AuthStorage();

/// Callback invoked when a refresh attempt fails terminally — refresh token
/// expired / revoked. The AuthController hooks this to sign the user out
/// and let the router redirect to /auth.
typedef OnSessionExpired = void Function();

class ApiClient {
  ApiClient({Dio? dio, OnSessionExpired? onSessionExpired})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 15),
                // Deliberately no pinned Content-Type: Dio auto-sets
                // application/json for Map bodies and multipart/form-data
                // for FormData. Pinning here leaked JSON Content-Type into
                // multipart avatar uploads.
                headers: {'Accept': 'application/json'},
              ),
            ),
        _onSessionExpired = onSessionExpired {
    // Order matters. _AuthInterceptor stamps the header and, on a 401,
    // does a one-shot refresh + retry. _RetryInterceptor handles transient
    // 5xx. _ErrorInterceptor is last because it *throws* domain
    // exceptions, terminating the chain.
    _dio.interceptors.addAll([
      _LocaleInterceptor(),
      _AuthInterceptor(_dio, _onSessionExpired),
      _RetryInterceptor(_dio),
      if (Env.isDev) _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;

  /// Dio wraps anything an interceptor throws in a
  /// `DioException(type: unknown, error: <thrown>)`, so the domain
  /// exceptions raised by [_ErrorInterceptor] would otherwise reach callers
  /// as an opaque DioException — `on RateLimitException` / `FriendlyError`
  /// type checks would never match. Re-throw the domain exception itself.
  static Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e, st) {
      final inner = e.error;
      if (_isDomainException(inner)) {
        Error.throwWithStackTrace(inner!, st);
      }
      rethrow;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _send(() => _dio.put<dynamic>(path, data: data));
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<void> delete(String path) async {
    await _send(() => _dio.delete<dynamic>(path));
  }

  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    T Function(dynamic)? fromJson,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    final response =
        await _send(() => _dio.post<dynamic>(path, data: formData));
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }
}

bool _isDomainException(Object? e) =>
    e is ServerException ||
    e is NetworkException ||
    e is AuthException ||
    e is RateLimitException ||
    e is CacheException;

/// Thrown by [_refreshTokens] when the backend rejected the refresh token
/// (401/403): the session is dead and the user must sign in again.
class _SessionDeadException implements Exception {
  const _SessionDeadException();
}

/// The refresh currently in flight, shared by every [ApiClient] instance
/// (some widgets build their own client). The backend rotates refresh
/// tokens with reuse detection, so two concurrent refreshes with the same
/// token would get the second one rejected — and log the user out.
Future<AuthTokens>? _inflightRefresh;

/// Exchanges the stored refresh token for a new pair, single-flight.
/// Throws [_SessionDeadException] only when the server rejected the
/// refresh token; network errors / 5xx propagate as-is (tokens are kept).
Future<AuthTokens> _refreshTokens(BaseOptions options, String refreshToken) {
  return _inflightRefresh ??= () async {
    try {
      // A bare Dio (no app interceptors) so the refresh call itself can't
      // recurse into the 401 handler or be retried, and so the raw status
      // code is available below.
      final dio = Dio(
        BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: options.connectTimeout,
          receiveTimeout: options.receiveTimeout,
          sendTimeout: options.sendTimeout,
          headers: {
            'Accept': 'application/json',
            'Accept-Language': currentLocaleCode,
          },
        ),
      );
      final Response<dynamic> resp;
      try {
        resp = await dio.post<dynamic>(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          throw const _SessionDeadException();
        }
        rethrow;
      }
      final data =
          (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final newTokens = AuthTokens.fromJson(
        data['tokens'] as Map<String, dynamic>,
      );
      await authStorage.write(newTokens);
      return newTokens;
    } finally {
      _inflightRefresh = null;
    }
  }();
}

/// Stamps `Authorization: Bearer <access>` on every request and, on a 401,
/// refreshes the access token (single-flight across concurrent requests)
/// and retries the original request once. Auth endpoints themselves
/// (register / login / refresh / password-reset) don't get the header —
/// they're the calls that CREATE the token, so a stale one is worse than
/// none.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._onSessionExpired);

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/otp/request') ||
        path.contains('/auth/register') ||
        path.contains('/auth/login') ||
        path.contains('/auth/password/reset') ||
        path.contains('/auth/refresh') ||
        path.contains('/legal/') ||
        path.contains('/places/search');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }
    // If a refresh is already running, wait for it rather than firing a
    // request with an access token we already know is stale.
    final pending = _inflightRefresh;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {/* fall through with whatever is stored */}
    }
    final tokens = await authStorage.read();
    if (tokens != null && tokens.accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['_refreshed'] == true;
    if (status != 401 ||
        alreadyRetried ||
        _isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    final tokens = await authStorage.read();
    if (tokens == null || tokens.refreshExpired) {
      await authStorage.clear();
      _onSessionExpired?.call();
      handler.next(err);
      return;
    }

    final AuthTokens fresh;
    final sentAuth = err.requestOptions.headers['Authorization'];
    if (sentAuth != null && sentAuth != 'Bearer ${tokens.accessToken}') {
      // Another request already refreshed while this one was in flight —
      // just retry with the newer token.
      fresh = tokens;
    } else {
      try {
        fresh = await _refreshTokens(_dio.options, tokens.refreshToken);
      } on _SessionDeadException {
        // The server rejected the refresh token — the session is over.
        // Wipe stored tokens, notify the app, surface the original 401 so
        // callers can route to sign-in.
        await authStorage.clear();
        _onSessionExpired?.call();
        handler.next(err);
        return;
      } catch (_) {
        // Transient failure (offline, timeout, 5xx). Keep the tokens so
        // the next request can try again; surface the original error.
        handler.next(err);
        return;
      }
    }

    err.requestOptions.extra['_refreshed'] = true;
    err.requestOptions.headers['Authorization'] =
        'Bearer ${fresh.accessToken}';
    try {
      final retryResp = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retryResp);
    } on DioException catch (e) {
      // The retry already went through the full interceptor chain; pass
      // its (wrapped domain) error straight out.
      handler.reject(e);
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Already mapped (e.g. the failure of a retried request).
    final inner = err.error;
    if (inner is Exception && _isDomainException(inner)) throw inner;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;
        String? message;
        String? code;
        if (data is Map<String, dynamic>) {
          final errorMap = data['error'] as Map<String, dynamic>?;
          message = errorMap?['message'] as String?;
          code = errorMap?['code'] as String?;
        }
        if (statusCode == 401) {
          throw AuthException(
            message: message ?? 'Session expired. Please sign in again.',
            code: code,
          );
        }
        if (statusCode == 429) {
          int? used;
          int? limit;
          DateTime? resetAt;
          if (data is Map<String, dynamic>) {
            final errorMap = data['error'];
            if (errorMap is Map<String, dynamic>) {
              used = (errorMap['used'] as num?)?.toInt();
              limit = (errorMap['limit'] as num?)?.toInt();
              final raw = errorMap['reset_at'];
              if (raw is String) resetAt = DateTime.tryParse(raw);
            }
          }
          throw RateLimitException(
            message: message ?? 'Rate limit exceeded.',
            code: code,
            used: used,
            limit: limit,
            resetAt: resetAt,
          );
        }
        throw ServerException(
          message: message ?? ServerException.fallbackMessage,
          statusCode: statusCode,
          code: code,
        );
      // ignore: no_default_cases
      default:
        throw ServerException(
          message: err.message ?? ServerException.fallbackMessage,
        );
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[API] ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[API] ERROR ${err.response?.statusCode} ${err.requestOptions.path}: '
      '${err.message}',
    );
    handler.next(err);
  }
}

/// Stamps `Accept-Language` on every outgoing request so the backend
/// can tell the LLM which language to answer in, and switch its own
/// chart-summary and deterministic-forecast templates.
class _LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = currentLocaleCode;
    handler.next(options);
  }
}

/// Retries transient 5xx responses — for idempotent methods only. A POST
/// (payments, chat messages, posts) may have been applied server-side
/// before the 5xx, so replaying it could duplicate the side effect.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const _maxRetries = 2;
  static const _retryableStatuses = {500, 502, 503, 504};
  static const _idempotentMethods = {'GET', 'HEAD', 'PUT', 'DELETE'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    final method = err.requestOptions.method.toUpperCase();

    if (statusCode != null &&
        _retryableStatuses.contains(statusCode) &&
        _idempotentMethods.contains(method) &&
        retryCount < _maxRetries) {
      await Future<void>.delayed(
        Duration(milliseconds: 500 * (retryCount + 1)),
      );
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
      } on DioException catch (e) {
        // The retry ran the full interceptor chain (including its own
        // further retries); surface its final error.
        handler.reject(e);
      }
      return;
    }
    handler.next(err);
  }
}
