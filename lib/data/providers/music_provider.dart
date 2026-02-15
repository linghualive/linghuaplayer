import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class MusicProvider {
  final _dio = HttpClient.instance.dio;

  // Audio/Music endpoints use www.bilibili.com as base,
  // so we need full URL since Dio baseUrl is api.bilibili.com.

  /// Get hot/popular audio playlists
  Future<Response> getHotPlaylists({int pn = 1, int ps = 6}) {
    return _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.audioHotPlaylists}',
      queryParameters: {'pn': pn, 'ps': ps},
    );
  }

  /// Get audio playlist detail info
  Future<Response> getPlaylistInfo(int menuId) {
    return _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.audioPlaylistInfo}',
      queryParameters: {'sid': menuId},
    );
  }

  /// Get songs in an audio playlist
  Future<Response> getPlaylistSongs(int menuId, {int pn = 1, int ps = 100}) {
    return _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.audioPlaylistSongs}',
      queryParameters: {'sid': menuId, 'pn': pn, 'ps': ps},
    );
  }

  /// Get audio song info
  Future<Response> getSongInfo(int songId) {
    return _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.audioSongInfo}',
      queryParameters: {'sid': songId},
    );
  }

  /// Get audio stream URL
  Future<Response> getAudioUrl(int songId, {int quality = 3}) {
    return _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.audioUrl}',
      queryParameters: {
        'sid': songId,
        'privilege': 2,
        'quality': quality,
      },
    );
  }

  // Ranking & MV endpoints use api.bilibili.com (default Dio base).

  /// Get all ranking periods
  Future<Response> getRankPeriods() {
    return _dio.get(
      ApiConstants.musicRankPeriods,
      queryParameters: {'list_type': 1},
    );
  }

  /// Get ranking song list for a period
  Future<Response> getRankSongs(int listId, {int pn = 1, int ps = 10}) {
    return _dio.get(
      ApiConstants.musicRankSongs,
      queryParameters: {'list_id': listId, 'pn': pn, 'ps': ps},
    );
  }

  /// Get MV list
  Future<Response> getMvList({int pn = 1, int ps = 10, int order = 0}) {
    return _dio.get(
      ApiConstants.mvList,
      queryParameters: {'pn': pn, 'ps': ps, 'order': order},
    );
  }

  /// Get partition ranking (e.g. music zone rid=3)
  Future<Response> getPartitionRanking(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.partitionRanking,
      queryParameters: params,
    );
  }
}
