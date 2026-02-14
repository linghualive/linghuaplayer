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

  Future<Response> getFavFoldersAll({
    required int upMid,
    int? rid,
  }) {
    final params = <String, dynamic>{'up_mid': upMid};
    if (rid != null) params['rid'] = rid;
    return _dio.get(
      ApiConstants.favFolderListAll,
      queryParameters: params,
    );
  }

  Future<Response> favResourceDeal({
    required int rid,
    required String addMediaIds,
    required String delMediaIds,
    required String csrf,
  }) {
    return _dio.post(
      ApiConstants.favResourceDeal,
      data:
          'rid=$rid&type=2&add_media_ids=$addMediaIds&del_media_ids=$delMediaIds&csrf=$csrf',
    );
  }

  Future<Response> hasFavVideo({required int aid}) {
    return _dio.get(
      ApiConstants.hasFavVideo,
      queryParameters: {'aid': aid},
    );
  }

  Future<Response> addFavFolder({
    required String title,
    required String intro,
    required int privacy,
    required String csrf,
  }) {
    return _dio.post(
      ApiConstants.addFavFolder,
      data: 'title=$title&intro=$intro&privacy=$privacy&csrf=$csrf',
    );
  }

  Future<Response> editFavFolder({
    required String title,
    required String intro,
    required int mediaId,
    required int privacy,
    required String csrf,
  }) {
    return _dio.post(
      ApiConstants.editFavFolder,
      data:
          'title=$title&intro=$intro&media_id=$mediaId&privacy=$privacy&csrf=$csrf',
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
