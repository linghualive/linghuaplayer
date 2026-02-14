import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class RecommendProvider {
  final _dio = HttpClient.instance.dio;

  Future<Response> getTopFeedRcmd({
    required int freshIdx,
    int brush = 1,
  }) {
    return _dio.get(
      ApiConstants.topFeedRcmd,
      queryParameters: {
        'version': 1,
        'feed_version': 'V3',
        'homepage_ver': 1,
        'ps': 20,
        'fresh_idx': freshIdx,
        'brush': brush,
        'fresh_type': 4,
      },
    );
  }
}
