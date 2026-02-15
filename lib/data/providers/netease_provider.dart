import 'package:dio/dio.dart';

import '../../core/http/netease_http_client.dart';

/// Provider for NetEase Cloud Music API.
///
/// Calls NetEase servers directly using WEAPI encryption.
/// API paths follow the internal NetEase endpoint conventions.
class NeteaseProvider {
  final _client = NeteaseHttpClient.instance;

  Future<Response> search(String keywords, {int limit = 30, int offset = 0}) {
    return _client.weapiRequest('/api/search/get', {
      's': keywords,
      'type': 1, // 1: songs
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> getSongUrl(int id, {String level = 'standard'}) {
    return _client.eapiRequest('/api/song/enhance/player/url/v1', {
      'ids': '[$id]',
      'level': level,
      'encodeType': 'flac',
    });
  }

  Future<Response> getSongDetail(List<int> ids) {
    final c = ids.map((id) => '{"id":$id}').join(',');
    return _client.weapiRequest('/api/v3/song/detail', {
      'c': '[$c]',
    });
  }

  Future<Response> getLyrics(int id) {
    return _client.weapiRequest('/api/song/lyric', {
      'id': id,
      'tv': -1,
      'lv': -1,
      'rv': -1,
      'kv': -1,
      '_nmclfl': 1,
    });
  }

  Future<Response> getPersonalized({int limit = 6}) {
    return _client.weapiRequest('/api/personalized/playlist', {
      'limit': limit,
      'total': true,
      'n': 1000,
    });
  }

  Future<Response> getTopSong({int type = 0}) {
    return _client.weapiRequest('/api/v1/discovery/new/songs', {
      'areaId': type, // 0: all, 7: CN, 96: West, 8: JP, 16: KR
      'total': true,
    });
  }

  // ── Auth: QR Login (EAPI, matching api-enhanced) ────

  Future<Response> getQrKey() {
    return _client.eapiRequest('/api/login/qrcode/unikey', {
      'type': 3,
    });
  }

  Future<Response> pollQrLogin(String key) {
    return _client.eapiRequest('/api/login/qrcode/client/login', {
      'key': key,
      'type': 3,
    });
  }

  Future<Response> getAccountInfo() {
    return _client.weapiRequest('/api/w/nuser/account/get', {});
  }

  // ── Personalized Recommendations (requires login) ──

  Future<Response> getDailyRecommendSongs() {
    return _client.weapiRequest('/api/v3/discovery/recommend/songs', {});
  }

  Future<Response> getDailyRecommendPlaylists() {
    return _client.weapiRequest('/api/v1/discovery/recommend/resource', {});
  }

  // ── User Playlists & Detail ─────────────────────────

  Future<Response> getUserPlaylists(int uid, {int limit = 30, int offset = 0}) {
    return _client.weapiRequest('/api/user/playlist', {
      'uid': uid,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> getPlaylistDetail(int id) {
    return _client.weapiRequest('/api/v6/playlist/detail', {
      'id': id,
      'n': 100000,
    });
  }
}
