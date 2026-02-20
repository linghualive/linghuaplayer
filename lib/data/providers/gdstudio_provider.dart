import 'package:dio/dio.dart';

/// HTTP provider for the GD Studio Music API.
///
/// API base: https://music-api.gdstudio.xyz/api.php
/// Stable sub-sources: netease, kuwo, joox, bilibili
class GdStudioProvider {
  static const _baseUrl = 'https://music-api.gdstudio.xyz/api.php';

  final Dio _dio;

  GdStudioProvider()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                'AppleWebKit/537.36 (KHTML, like Gecko)',
          },
        ));

  /// Search for tracks.
  ///
  /// [source] - Sub-source: netease, kuwo, joox, bilibili, etc.
  /// [name] - Search keyword.
  /// [count] - Results per page (default 20).
  /// [pages] - Page number (1-based, default 1).
  Future<Response> search({
    required String source,
    required String name,
    int count = 20,
    int pages = 1,
  }) {
    return _dio.get('', queryParameters: {
      'types': 'search',
      'source': source,
      'name': name,
      'count': count,
      'pages': pages,
    });
  }

  /// Get playable URL for a track.
  ///
  /// [br] - Bitrate: 128, 192, 320, 740, 999 (lossless).
  Future<Response> getUrl({
    required String source,
    required String id,
    int br = 999,
  }) {
    return _dio.get('', queryParameters: {
      'types': 'url',
      'source': source,
      'id': id,
      'br': br,
    });
  }

  /// Get album cover image URL.
  ///
  /// [size] - 300 (small) or 500 (large).
  Future<Response> getPic({
    required String source,
    required String id,
    int size = 500,
  }) {
    return _dio.get('', queryParameters: {
      'types': 'pic',
      'source': source,
      'id': id,
      'size': size,
    });
  }

  /// Get lyrics for a track (LRC format).
  Future<Response> getLyric({
    required String source,
    required String id,
  }) {
    return _dio.get('', queryParameters: {
      'types': 'lyric',
      'source': source,
      'id': id,
    });
  }
}
