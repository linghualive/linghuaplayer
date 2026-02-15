import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:flamekit/core/crypto/buvid.dart';
import 'package:flamekit/core/storage/storage_service.dart';
import 'package:get/get.dart';

class ApiInterceptor extends dio.Interceptor {
  bool _isRetrying = false;

  @override
  void onResponse(
      dio.Response response, dio.ResponseInterceptorHandler handler) {
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

    // Handle 412 risk control: re-activate BUVID and retry once
    if (response.statusCode == 412 && !_isRetrying) {
      _handleRiskControl(response, handler);
      return;
    }

    handler.next(response);
  }

  Future<void> _handleRiskControl(
    dio.Response response,
    dio.ResponseInterceptorHandler handler,
  ) async {
    _isRetrying = true;
    try {
      log('412 risk control detected, re-activating BUVID...');
      await BuvidUtil.getBuvid();
      await BuvidUtil.activate();

      // Retry the original request
      final options = response.requestOptions;
      final retryResponse = await dio.Dio().fetch(options);
      log('412 retry succeeded');
      handler.next(retryResponse);
    } catch (e) {
      log('412 retry failed: $e');
      // Return the original 412 response so the caller can handle it
      handler.next(response);
    } finally {
      _isRetrying = false;
    }
  }

  @override
  void onError(dio.DioException err, dio.ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
