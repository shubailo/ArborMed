/// Typed API exceptions for structured error handling.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 Unauthorized — token expired or invalid.
class AuthException extends ApiException {
  const AuthException({super.message = 'Authentication failed', super.body})
      : super(statusCode: 401);
}

/// 403 Forbidden — insufficient permissions.
class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = 'Access denied', super.body})
      : super(statusCode: 403);
}

/// 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Resource not found', super.body})
      : super(statusCode: 404);
}

/// 409 Conflict — e.g. duplicate resource or constraint violation.
class ConflictException extends ApiException {
  const ConflictException({super.message = 'Resource conflict', super.body})
      : super(statusCode: 409);
}

/// 5xx Server Error.
class ServerException extends ApiException {
  const ServerException(
      {super.statusCode = 500,
      super.message = 'Internal server error',
      super.body});
}

/// Network errors — no internet, DNS, timeout.
class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network error'})
      : super(statusCode: 0);
}
