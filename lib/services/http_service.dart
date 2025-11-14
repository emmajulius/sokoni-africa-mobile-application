import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for HTTP requests with timeout, retry logic, and better error handling
class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  /// Default timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Default number of retries
  static const int defaultMaxRetries = 3;
  
  /// Delay between retries
  static const Duration retryDelay = Duration(seconds: 2);

  /// Make a GET request with timeout and retry logic
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = defaultMaxRetries,
  }) async {
    return _requestWithRetry(
      () => http.get(url, headers: headers),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries,
    );
  }

  /// Make a POST request with timeout and retry logic
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    int maxRetries = defaultMaxRetries,
  }) async {
    return _requestWithRetry(
      () => http.post(url, headers: headers, body: body),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries,
    );
  }

  /// Make a PUT request with timeout and retry logic
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    int maxRetries = defaultMaxRetries,
  }) async {
    return _requestWithRetry(
      () => http.put(url, headers: headers, body: body),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries,
    );
  }

  /// Make a DELETE request with timeout and retry logic
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = defaultMaxRetries,
  }) async {
    return _requestWithRetry(
      () => http.delete(url, headers: headers),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries,
    );
  }

  /// Execute a request with retry logic
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request, {
    required Duration timeout,
    required int maxRetries,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      try {
        if (kDebugMode && attempt > 0) {
          print('🔄 Retry attempt ${attempt + 1}/$maxRetries');
        }

        final response = await request().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
              'Request timed out after ${timeout.inSeconds} seconds',
              timeout,
            );
          },
        );

        // If successful, return response
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // Don't retry on client errors (4xx) except for 408 (Request Timeout)
        if (response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 408) {
          return response;
        }

        // For server errors (5xx) or timeout (408), retry
        if (kDebugMode) {
          print('⚠️ Request failed with status ${response.statusCode}, will retry');
        }
        
        lastException = Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry on certain exceptions
        if (e is SocketException || e is FormatException) {
          if (kDebugMode) {
            print('❌ Non-retryable error: $e');
          }
          rethrow;
        }

        if (kDebugMode) {
          print('⚠️ Request failed: $e');
        }
      }

      // Wait before retrying
      if (attempt < maxRetries - 1) {
        await Future.delayed(retryDelay * (attempt + 1)); // Exponential backoff
      }

      attempt++;
    }

    // All retries exhausted
    if (kDebugMode) {
      print('❌ All retry attempts exhausted');
    }
    throw lastException ?? Exception('Request failed after $maxRetries attempts');
  }
}

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}


