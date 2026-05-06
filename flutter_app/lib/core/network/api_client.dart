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
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      if (Env.isDev) _LoggingInterceptor(),
      _RetryInterceptor(_dio),
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
  ///
  /// We explicitly clear the base `Content-Type: application/json`
  /// header on this request — Dio's FormData transformer normally
  /// rewrites it to `multipart/form-data; boundary=...`, but if the
  /// JSON header has been pinned via `BaseOptions.headers` it can leak
  /// through and the backend then fails to parse the multipart body.
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    T Function(dynamic)? fromJson,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      options: Options(
        headers: {
          // Explicitly null this so Dio's transformer sets the proper
          // multipart Content-Type with its boundary.
          Headers.contentTypeHeader: null,
        },
      ),
    );
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
      try {
        final token = await user.getIdToken();
        options.headers['Authorization'] = 'Bearer $token';
      } catch (_) {
        // Continue without token; server will return 401 if needed.
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
