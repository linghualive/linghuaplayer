import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class LyricsProvider {
  /// Separate Dio for LRCLIB (no bilibili auth/cookies needed)
  final _lrclibDio = Dio(BaseOptions(
    baseUrl: 'https://lrclib.net',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.json,
  ));

  /// Bilibili Dio for subtitle API (needs WBI signing)
  final _dio = HttpClient.instance.dio;

  /// Search LRCLIB by track name + optional artist
  Future<Response> searchLrclib(String trackName, {String? artistName}) {
    final params = <String, dynamic>{'track_name': trackName};
    if (artistName != null && artistName.isNotEmpty) {
      params['artist_name'] = artistName;
    }
    return _lrclibDio.get('/api/search', queryParameters: params);
  }

  /// General keyword search on LRCLIB
  Future<Response> searchLrclibByQuery(String query) {
    return _lrclibDio.get(
      '/api/search',
      queryParameters: {'q': query},
    );
  }

  /// Get player/subtitle info from Bilibili (WBI-signed params)
  Future<Response> getSubtitleInfo(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.playerInfo,
      queryParameters: params,
    );
  }

  /// Fetch raw subtitle JSON from a subtitle URL
  Future<Response> fetchSubtitleJson(String url) {
    // Subtitle URLs may be protocol-relative
    final fullUrl = url.startsWith('//') ? 'https:$url' : url;
    return _lrclibDio.get(fullUrl);
  }
}
