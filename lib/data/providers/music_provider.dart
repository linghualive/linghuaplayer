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

  /// Get partition ranking (e.g. music zone rid=3)
  Future<Response> getPartitionRanking(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.partitionRanking,
      queryParameters: params,
    );
  }

  /// Get related videos for a given bvid
  Future<Response> getRelatedVideos(String bvid) {
    return _dio.get(
      ApiConstants.relatedVideos,
      queryParameters: {'bvid': bvid},
    );
  }

  /// Get member archive (user's uploaded videos), params should be WBI-signed
  Future<Response> getMemberArchive(Map<String, dynamic> params) {
    return _dio.get(
      ApiConstants.memberArchive,
      queryParameters: params,
    );
  }

  /// Get member seasons & series (合集/系列)
  Future<Response> getMemberSeasons(int mid, {int pn = 1, int ps = 20}) {
    return _dio.get(
      ApiConstants.memberSeasons,
      queryParameters: {'mid': mid, 'page_num': pn, 'page_size': ps},
    );
  }

  /// Get season detail (合集详情)
  Future<Response> getSeasonDetail({
    required int mid,
    required int seasonId,
    int pn = 1,
    int ps = 30,
    bool sortReverse = false,
  }) {
    return _dio.get(
      ApiConstants.seasonDetail,
      queryParameters: {
        'mid': mid,
        'season_id': seasonId,
        'sort_reverse': sortReverse,
        'page_num': pn,
        'page_size': ps,
      },
    );
  }

  /// Get series detail (系列详情)
  Future<Response> getSeriesDetail({
    required int mid,
    required int seriesId,
    int pn = 1,
    int ps = 30,
  }) {
    return _dio.get(
      ApiConstants.seriesDetail,
      queryParameters: {
        'mid': mid,
        'series_id': seriesId,
        'only_normal': true,
        'sort': 'desc',
        'pn': pn,
        'ps': ps,
      },
    );
  }
}
