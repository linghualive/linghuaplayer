import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class UserProvider {
  final _dio = HttpClient.instance.dio;

  // Favorites
  Future<Response> getFavFolders({
    required int upMid,
    int pn = 1,
    int ps = 20,
  }) {
    return _dio.get(
      ApiConstants.favFolderList,
      queryParameters: {'up_mid': upMid, 'pn': pn, 'ps': ps},
    );
  }

  Future<Response> getFavResources({
    required int mediaId,
    int pn = 1,
    int ps = 20,
    String order = 'mtime',
  }) {
    return _dio.get(
      ApiConstants.favResourceList,
      queryParameters: {
        'media_id': mediaId,
        'pn': pn,
        'ps': ps,
        'order': order,
      },
    );
  }

  // Subscriptions
  Future<Response> getSubFolders({
    required int upMid,
    int pn = 1,
    int ps = 20,
  }) {
    return _dio.get(
      ApiConstants.subFolderList,
      queryParameters: {'up_mid': upMid, 'pn': pn, 'ps': ps},
    );
  }

  Future<Response> getSubSeasonVideos({
    required int seasonId,
    int pn = 1,
    int ps = 20,
  }) {
    return _dio.get(
      ApiConstants.subSeasonList,
      queryParameters: {'season_id': seasonId, 'pn': pn, 'ps': ps},
    );
  }

  // Watch Later
  Future<Response> getWatchLaterList() {
    return _dio.get(ApiConstants.watchLaterList);
  }

  Future<Response> deleteWatchLater({
    required int aid,
    required String csrf,
  }) {
    return _dio.post(
      ApiConstants.watchLaterDel,
      data: 'aid=$aid&csrf=$csrf',
    );
  }

  Future<Response> clearWatchLater({required String csrf}) {
    return _dio.post(
      ApiConstants.watchLaterClear,
      data: 'csrf=$csrf',
    );
  }

  // Watch History
  Future<Response> getHistoryCursor({
    int max = 0,
    int viewAt = 0,
    int ps = 20,
  }) {
    return _dio.get(
      ApiConstants.historyCursor,
      queryParameters: {'max': max, 'view_at': viewAt, 'ps': ps},
    );
  }

  Future<Response> deleteHistory({
    required String kid,
    required String csrf,
  }) {
    return _dio.post(
      ApiConstants.historyDelete,
      data: 'kid=$kid&csrf=$csrf',
    );
  }

  Future<Response> clearHistory({required String csrf}) {
    return _dio.post(
      ApiConstants.historyClear,
      data: 'csrf=$csrf',
    );
  }
}
