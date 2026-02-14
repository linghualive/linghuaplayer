import 'package:dio/dio.dart' as dio;
import 'package:flamekit/core/storage/storage_service.dart';
import 'package:get/get.dart';

class ApiInterceptor extends dio.Interceptor {
  @override
  void onResponse(dio.Response response, dio.ResponseInterceptorHandler handler) {
    // Extract access_key from 302 redirects to mcbbs.net
    if (response.statusCode == 302) {
      final locations = response.headers['location'];
      if (locations != null && locations.isNotEmpty) {
        final location = locations.first;
        if (location.startsWith('https://www.mcbbs.net')) {
          final uri = Uri.parse(location);
          final accessKey = uri.queryParameters['access_key'];
          final mid = uri.queryParameters['mid'];
          if (accessKey != null) {
            final storage = Get.find<StorageService>();
            storage.setAccessKey(accessKey, mid: mid);
          }
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(dio.DioException err, dio.ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
