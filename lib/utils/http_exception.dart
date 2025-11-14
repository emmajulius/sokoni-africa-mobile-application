/// Custom exception for HTTP errors with status code support
class HttpException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorMessage;

  HttpException(this.message, {this.statusCode, this.errorMessage});

  @override
  String toString() => message;
}

