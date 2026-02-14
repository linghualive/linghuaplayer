class AppException implements Exception {
  final String message;
  final int? code;
  final dynamic data;

  AppException(this.message, {this.code, this.data});

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

class ApiException extends AppException {
  ApiException(super.message, {super.code, super.data});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}
