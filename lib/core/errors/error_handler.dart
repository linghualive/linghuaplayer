import 'package:dio/dio.dart';

import '../../shared/utils/app_toast.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    if (error is AppException) {
      return error;
    }
    return AppException(error.toString());
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ApiException(
          'Server error: $statusCode',
          code: statusCode,
        );
      default:
        return NetworkException(error.message ?? 'Network error');
    }
  }

  static void showError(dynamic error) {
    final exception = handle(error);
    AppToast.error(exception.message);
  }
}
