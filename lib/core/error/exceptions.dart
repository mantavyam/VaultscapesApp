/// Custom exceptions for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});
}

/// Cache related exceptions
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.originalError});
}

/// Not found exception
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// Validation exception
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(super.message, {this.fieldErrors, super.code, super.originalError});
}

/// Server exception
class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {this.statusCode, super.code, super.originalError});
}
