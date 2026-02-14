import 'package:get/get.dart';

import '../../core/http/http_client.dart';
import '../models/user/fav_folder_model.dart';
import '../models/user/fav_resource_model.dart';
import '../models/user/history_model.dart';
import '../models/user/sub_folder_model.dart';
import '../models/user/sub_resource_model.dart';
import '../models/user/watch_later_model.dart';
import '../providers/user_provider.dart';

class UserRepository {
  final _provider = Get.find<UserProvider>();

  // ── Favorites ──

  Future<List<FavFolderModel>> getFavFolders({
    required int upMid,
    int pn = 1,
    int ps = 20,
  }) async {
    final res = await _provider.getFavFolders(upMid: upMid, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['list'] as List<dynamic>? ?? [];
      return list
          .map((e) => FavFolderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<({List<FavResourceModel> items, bool hasMore})> getFavResources({
    required int mediaId,
    int pn = 1,
    int ps = 20,
  }) async {
    final res = await _provider.getFavResources(
        mediaId: mediaId, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final medias = data['medias'] as List<dynamic>? ?? [];
      final hasMore = data['has_more'] as bool? ?? false;
      return (
        items: medias
            .map((e) => FavResourceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: hasMore,
      );
    }
    return (items: <FavResourceModel>[], hasMore: false);
  }

  // ── Subscriptions ──

  Future<({List<SubFolderModel> items, bool hasMore})> getSubFolders({
    required int upMid,
    int pn = 1,
    int ps = 20,
  }) async {
    final res = await _provider.getSubFolders(upMid: upMid, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>? ?? [];
      final hasMore = data['has_more'] as bool? ?? false;
      return (
        items: list
            .map((e) => SubFolderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: hasMore,
      );
    }
    return (items: <SubFolderModel>[], hasMore: false);
  }

  Future<({List<SubResourceModel> items, bool hasMore})> getSubSeasonVideos({
    required int seasonId,
    int pn = 1,
    int ps = 20,
  }) async {
    final res = await _provider.getSubSeasonVideos(
        seasonId: seasonId, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final medias = data['medias'] as List<dynamic>? ?? [];
      final info = data['info'] as Map<String, dynamic>? ?? {};
      final total = info['total'] as int? ?? 0;
      final hasMore = pn * ps < total;
      return (
        items: medias
            .map((e) => SubResourceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: hasMore,
      );
    }
    return (items: <SubResourceModel>[], hasMore: false);
  }

  // ── Watch Later ──

  Future<List<WatchLaterModel>> getWatchLaterList() async {
    final res = await _provider.getWatchLaterList();
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['list'] as List<dynamic>? ?? [];
      return list
          .map((e) => WatchLaterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<bool> deleteWatchLater(int aid) async {
    final csrf = await HttpClient.instance.getCsrf();
    final res = await _provider.deleteWatchLater(aid: aid, csrf: csrf);
    return res.data['code'] == 0;
  }

  Future<bool> clearWatchLater() async {
    final csrf = await HttpClient.instance.getCsrf();
    final res = await _provider.clearWatchLater(csrf: csrf);
    return res.data['code'] == 0;
  }

  // ── Watch History ──

  Future<({List<HistoryModel> items, int cursor, int viewAt})>
      getHistoryCursor({
    int max = 0,
    int viewAt = 0,
    int ps = 20,
  }) async {
    final res = await _provider.getHistoryCursor(
        max: max, viewAt: viewAt, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>? ?? [];
      final cursorData = data['cursor'] as Map<String, dynamic>? ?? {};
      return (
        items: list
            .where((e) =>
                (e as Map<String, dynamic>)['history']?['bvid'] != null &&
                (e['history']['bvid'] as String).isNotEmpty)
            .map((e) => HistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        cursor: cursorData['max'] as int? ?? 0,
        viewAt: cursorData['view_at'] as int? ?? 0,
      );
    }
    return (items: <HistoryModel>[], cursor: 0, viewAt: 0);
  }

  Future<bool> deleteHistory(String kid) async {
    final csrf = await HttpClient.instance.getCsrf();
    final res = await _provider.deleteHistory(kid: kid, csrf: csrf);
    return res.data['code'] == 0;
  }

  Future<bool> clearHistory() async {
    final csrf = await HttpClient.instance.getCsrf();
    final res = await _provider.clearHistory(csrf: csrf);
    return res.data['code'] == 0;
  }
}
