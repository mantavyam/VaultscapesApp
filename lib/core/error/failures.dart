/// Base failure class for handling errors in the domain layer
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred. Please check your connection.']);
}

/// Server related failures
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure([super.message = 'Server error occurred. Please try again later.', this.statusCode]);
}

/// Cache related failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred.']);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please try again.']);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource not found.']);
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure([super.message = 'Validation failed.', this.fieldErrors]);
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred.']);
}
