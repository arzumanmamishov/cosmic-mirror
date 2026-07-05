import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/core/error/exceptions.dart';
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
      _AuthInterceptor(_dio, _onSessionExpired),
      _RetryInterceptor(_dio),
      if (Env.isDev) _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  final Dio _dio;
  final OnSessionExpired? _onSessionExpired;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
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
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.put<dynamic>(path, data: data);
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<void> delete(String path) async {
    await _dio.delete<dynamic>(path);
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
    final response = await _dio.post<dynamic>(path, data: formData);
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }
}

/// Stamps `Authorization: Bearer <access>` on every request and, on a 401,
/// attempts exactly one refresh-then-retry. Auth endpoints themselves
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
      _onSessionExpired?.call();
      handler.next(err);
      return;
    }
    try {
      final resp = await _dio.post<dynamic>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      final data =
          (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final newTokens = AuthTokens.fromJson(
        data['tokens'] as Map<String, dynamic>,
      );
      await authStorage.write(newTokens);

      err.requestOptions.extra['_refreshed'] = true;
      err.requestOptions.headers['Authorization'] =
          'Bearer ${newTokens.accessToken}';
      final retryResp = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(retryResp);
    } catch (_) {
      // Refresh failed for a reason other than a network hiccup — the
      // refresh is dead. Wipe stored tokens, notify the app, surface the
      // original 401 so callers can route to sign-in.
      await authStorage.clear();
      _onSessionExpired?.call();
      handler.next(err);
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
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
          message: message ?? 'An unexpected error occurred.',
          statusCode: statusCode,
          code: code,
        );
      // ignore: no_default_cases
      default:
        throw ServerException(
          message: err.message ?? 'An unexpected error occurred.',
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

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const _maxRetries = 2;
  static const _retryableStatuses = {500, 502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (statusCode != null &&
        _retryableStatuses.contains(statusCode) &&
        retryCount < _maxRetries) {
      await Future<void>.delayed(
        Duration(milliseconds: 500 * (retryCount + 1)),
      );
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to handler.next
      }
    }
    handler.next(err);
  }
}
