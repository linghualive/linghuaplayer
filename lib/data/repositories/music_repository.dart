import 'package:get/get.dart';

import '../models/music/audio_song_model.dart';
import '../models/music/hot_playlist_model.dart';
import '../models/music/music_rank_period_model.dart';
import '../models/music/music_rank_song_model.dart';
import '../models/music/mv_item_model.dart';
import '../models/music/playlist_detail_model.dart';
import '../providers/music_provider.dart';

class MusicRepository {
  final _provider = Get.find<MusicProvider>();

  /// Get hot/popular audio playlists
  Future<List<HotPlaylistModel>> getHotPlaylists(
      {int pn = 1, int ps = 6}) async {
    final res = await _provider.getHotPlaylists(pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => HotPlaylistModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get playlist detail info
  Future<PlaylistDetailModel?> getPlaylistInfo(int menuId) async {
    final res = await _provider.getPlaylistInfo(menuId);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      return PlaylistDetailModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Get songs in a playlist
  Future<List<AudioSongModel>> getPlaylistSongs(int menuId,
      {int pn = 1, int ps = 100}) async {
    final res = await _provider.getPlaylistSongs(menuId, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'];
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => AudioSongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get direct audio URL for a song
  Future<String?> getAudioUrl(int songId, {int quality = 3}) async {
    final res = await _provider.getAudioUrl(songId, quality: quality);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final cdns = res.data['data']['cdns'] as List<dynamic>? ?? [];
      if (cdns.isNotEmpty) {
        return cdns.first as String;
      }
    }
    return null;
  }

  /// Get all ranking periods, returns the latest one first.
  /// API returns a map grouped by year, we flatten and sort descending.
  Future<List<MusicRankPeriodModel>> getRankPeriods() async {
    final res = await _provider.getRankPeriods();
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final listMap =
          res.data['data']['list'] as Map<String, dynamic>? ?? {};
      final allPeriods = <MusicRankPeriodModel>[];
      for (final yearEntries in listMap.values) {
        if (yearEntries is List) {
          for (final e in yearEntries) {
            allPeriods.add(MusicRankPeriodModel.fromJson(
                e as Map<String, dynamic>));
          }
        }
      }
      // Sort by ID descending (latest first)
      allPeriods.sort((a, b) => b.id.compareTo(a.id));
      return allPeriods;
    }
    return [];
  }

  /// Get ranking songs for a specific list ID
  Future<List<MusicRankSongModel>> getRankSongs(int listId,
      {int pn = 1, int ps = 10}) async {
    final res = await _provider.getRankSongs(listId, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['list'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              MusicRankSongModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get MV list
  Future<List<MvItemModel>> getMvList(
      {int pn = 1, int ps = 10, int order = 0}) async {
    final res = await _provider.getMvList(pn: pn, ps: ps, order: order);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['result'] as List<dynamic>? ?? [];
      return list
          .map((e) => MvItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
