import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../config/env.dart';
import '../error/exceptions.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 15),
                // We deliberately do NOT pin Content-Type in BaseOptions:
                // Dio auto-sets it per request — `application/json` for
                // Map/JSON bodies, `multipart/form-data; boundary=...`
                // for FormData. Pinning it in BaseOptions caused avatar
                // uploads to leak the JSON Content-Type into multipart
                // requests and the backend rejected them.
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ) {
    // Order matters for onError: Dio runs error interceptors in
    // registration order, and _ErrorInterceptor *throws* (converting the
    // DioException into a domain exception), which terminates the chain.
    // _RetryInterceptor must therefore run BEFORE _ErrorInterceptor so it
    // still sees the raw status code and can retry transient 5xx; the
    // conversion to domain exceptions happens last.
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(_dio),
      if (Env.isDev) _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

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

  /// Upload a file as a multipart form POST. The file is sent under the
  /// field name `file` so the backend can read `r.FormFile("file")`.
  /// Dio sets the proper `multipart/form-data; boundary=...` header
  /// automatically because BaseOptions no longer pins Content-Type.
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

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      // First try the cached token (fast path). If that fails or comes
      // back empty, fall back to a forced refresh — this avoids the
      // race where Firebase returns null mid-token-refresh and we end
      // up firing unauthenticated requests in parallel (notably on the
      // Community tab which fans out to four simultaneous calls).
      String? token;
      try {
        token = await user.getIdToken();
      } catch (e) {
        debugPrint('[Auth] getIdToken failed (cached): $e');
      }
      if (token == null || token.isEmpty) {
        try {
          token = await user.getIdToken(true);
        } catch (e) {
          debugPrint('[Auth] getIdToken failed (forceRefresh): $e');
        }
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
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
          // Parse the structured limit payload (used / limit / reset_at)
          // when the backend provides it — used by the AI chat cap and
          // any future per-day quota error.
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
    final retryCount =
        err.requestOptions.extra['retryCount'] as int? ?? 0;

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
