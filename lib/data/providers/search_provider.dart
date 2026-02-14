import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class SearchProvider {
  final _dio = HttpClient.instance.dio;

  /// Get hot search keywords
  Future<Response> getHotSearch() {
    return _dio.get('${ApiConstants.searchBaseUrl}${ApiConstants.hotSearch}');
  }

  /// Get search suggestions
  Future<Response> getSuggestions(String term) {
    return _dio.get(
      '${ApiConstants.searchBaseUrl}${ApiConstants.searchSuggest}',
      queryParameters: {
        'term': term,
        'main_ver': 'v1',
        'highlight': term,
      },
    );
  }

  /// Search by type with WBI-signed params
  Future<Response> searchByType(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.searchByType,
      queryParameters: params,
    );
  }

  /// Get video page list (BV -> CID)
  Future<Response> getPagelist(String bvid) {
    return _dio.get(
      ApiConstants.pagelist,
      queryParameters: {'bvid': bvid},
    );
  }
}
