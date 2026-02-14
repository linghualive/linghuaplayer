import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class PlayerProvider {
  final _dio = HttpClient.instance.dio;

  /// Get play URL with WBI-signed params
  Future<Response> getPlayUrl(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.playUrl,
      queryParameters: params,
    );
  }
}
