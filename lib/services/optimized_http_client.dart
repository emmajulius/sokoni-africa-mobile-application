import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Optimized HTTP client with connection pooling and better performance
class OptimizedHttpClient {
  static final OptimizedHttpClient _instance = OptimizedHttpClient._internal();
  factory OptimizedHttpClient() => _instance;
  OptimizedHttpClient._internal() {
    _initializeClient();
  }

  late Dio _dio;
  Dio get dio => _dio;

  void _initializeClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      
      // Enable HTTP/2 and connection pooling
      persistentConnection: true,
      followRedirects: true,
      maxRedirects: 5,
      
      // Headers
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
      },
      
      // Enable compression
      validateStatus: (status) => status! < 500,
    ));

    // Add interceptors for logging and error handling
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }

    // Add retry interceptor for failed requests
    _dio.interceptors.add(RetryInterceptor(_dio));
  }

  /// Configure client for a specific base URL
  void configureBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Add authorization token
  void setAuthToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request with optimized settings
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options ?? Options(
          // Enable caching for GET requests
          extra: {
            'cache': true,
            'cacheKey': path,
          },
        ),
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GET request failed: $e');
      }
      rethrow;
    }
  }

  /// POST request with optimized settings
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ POST request failed: $e');
      }
      rethrow;
    }
  }

  /// Upload file with progress tracking
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fileKey: await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(minutes: 5), // Longer timeout for uploads
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ File upload failed: $e');
      }
      rethrow;
    }
  }

  /// Upload multiple files
  Future<Response> uploadMultipleFiles(
    String path,
    List<String> filePaths, {
    String fileKey = 'files',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map((filePath) => MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        )),
      );

      final formData = FormData.fromMap({
        ...?data,
        fileKey: files,
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(minutes: 10), // Longer timeout for multiple files
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Multiple files upload failed: $e');
      }
      rethrow;
    }
  }

  /// Dispose client
  void dispose() {
    _dio.close();
  }
}

/// Retry interceptor for failed requests
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;
  final Dio _dio;

  RetryInterceptor(this._dio, {
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      if (kDebugMode) {
        print('🔄 Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}');
      }

      // Wait before retry with exponential backoff
      await Future.delayed(retryDelay * (retryCount + 1));

      try {
        // Retry the request
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // If retry failed and we've reached max retries, reject
        if (retryCount + 1 >= maxRetries) {
          handler.reject(err);
          return;
        }
        // Otherwise, let it continue to next retry attempt
      }
    }

    handler.reject(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors or 5xx server errors
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

