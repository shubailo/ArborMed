class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? body;

  ApiException({this.statusCode, required this.message, this.body});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class AuthException extends ApiException {
  AuthException({String? body}) : super(statusCode: 401, message: 'Unauthorized', body: body);
}

class ForbiddenException extends ApiException {
  ForbiddenException({String? body}) : super(statusCode: 403, message: 'Forbidden', body: body);
}

class NotFoundException extends ApiException {
  NotFoundException({String? body}) : super(statusCode: 404, message: 'Not Found', body: body);
}

class ConflictException extends ApiException {
  ConflictException({String? body}) : super(statusCode: 409, message: 'Conflict', body: body);
}

class ServerException extends ApiException {
  final int statusCode;
  ServerException({required this.statusCode, String? body}) 
      : super(statusCode: statusCode, message: 'Server Error', body: body);
}
