import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';

import '../../core/crypto/wbi_sign.dart';
import '../models/music/audio_song_model.dart';
import '../models/music/hot_playlist_model.dart';
import '../models/music/music_rank_period_model.dart';
import '../models/music/music_rank_song_model.dart';
import '../models/music/mv_item_model.dart';
import '../models/music/playlist_detail_model.dart';
import '../models/search/search_video_model.dart';
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

  /// Get related videos for a given bvid
  Future<List<SearchVideoModel>> getRelatedVideos(String bvid) async {
    final res = await _provider.getRelatedVideos(bvid);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data'] as List<dynamic>? ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final owner = m['owner'] as Map<String, dynamic>? ?? {};
        final stat = m['stat'] as Map<String, dynamic>? ?? {};
        final dur = m['duration'] as int? ?? 0;
        final minutes = dur ~/ 60;
        final seconds = dur % 60;
        return SearchVideoModel(
          id: m['aid'] as int? ?? 0,
          author: owner['name'] as String? ?? '',
          mid: owner['mid'] as int? ?? 0,
          title: m['title'] as String? ?? '',
          description: m['desc'] as String? ?? '',
          pic: m['pic'] as String? ?? '',
          play: stat['view'] as int? ?? 0,
          danmaku: stat['danmaku'] as int? ?? 0,
          duration: '$minutes:${seconds.toString().padLeft(2, '0')}',
          bvid: m['bvid'] as String? ?? '',
        );
      }).toList();
    }
    return [];
  }

  static String _randomBase64(int minLen, int maxLen) {
    final rng = Random();
    final len = minLen + rng.nextInt(maxLen - minLen);
    final bytes = List.generate(len, (_) => rng.nextInt(256));
    final encoded = base64Encode(bytes);
    return encoded.length > 2
        ? encoded.substring(0, encoded.length - 2)
        : encoded;
  }

  /// Get member archive (user's uploaded videos)
  Future<List<SearchVideoModel>> getMemberArchive(int mid,
      {String order = 'pubdate', int pn = 1, int ps = 30}) async {
    final params = await WbiSign.makSign({
      'mid': mid,
      'ps': ps,
      'tid': 0,
      'pn': pn,
      'keyword': '',
      'order': order,
      'platform': 'web',
      'web_location': 1550101,
      'order_avoided': true,
      'dm_img_list': '[]',
      'dm_img_str': _randomBase64(16, 64),
      'dm_cover_img_str': _randomBase64(32, 128),
      'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
    });
    final res = await _provider.getMemberArchive(params);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final listData = data['list'] as Map<String, dynamic>? ?? {};
      final vlist = listData['vlist'] as List<dynamic>? ?? [];
      return vlist.map((e) {
        final m = e as Map<String, dynamic>;
        final dur = m['length'] as String? ?? '0:00';
        return SearchVideoModel(
          id: m['aid'] as int? ?? 0,
          author: m['author'] as String? ?? '',
          mid: m['mid'] as int? ?? 0,
          title: m['title'] as String? ?? '',
          description: m['description'] as String? ?? '',
          pic: m['pic'] as String? ?? '',
          play: m['play'] as int? ?? 0,
          danmaku: m['video_review'] as int? ?? 0,
          duration: dur,
          bvid: m['bvid'] as String? ?? '',
        );
      }).toList();
    }
    return [];
  }

  /// Get member seasons & series (合集/系列)
  Future<MemberSeasonsResult> getMemberSeasons(int mid,
      {int pn = 1, int ps = 20}) async {
    final res = await _provider.getMemberSeasons(mid, pn: pn, ps: ps);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final itemsLists =
          res.data['data']['items_lists'] as Map<String, dynamic>? ?? {};
      final page = itemsLists['page'] as Map<String, dynamic>? ?? {};
      final hasMore = (page['page_num'] as int? ?? 1) <
          ((page['total'] as int? ?? 0) / (page['page_size'] as int? ?? 1))
              .ceil();

      final seasonsList =
          itemsLists['seasons_list'] as List<dynamic>? ?? [];
      final seriesList =
          itemsLists['series_list'] as List<dynamic>? ?? [];

      final seasons = <MemberSeason>[];
      for (final item in [...seasonsList, ...seriesList]) {
        final m = item as Map<String, dynamic>;
        final meta = m['meta'] as Map<String, dynamic>? ?? {};
        final archives = m['archives'] as List<dynamic>? ?? [];

        seasons.add(MemberSeason(
          seasonId: meta['season_id'] as int? ?? 0,
          seriesId: meta['series_id'] as int? ?? 0,
          name: meta['name'] as String? ?? '',
          total: meta['total'] as int? ?? 0,
          cover: meta['cover'] as String? ?? '',
          category: meta['category'] as int? ?? 0,
          archives: archives.map((a) {
            final am = a as Map<String, dynamic>;
            final stat = am['stat'] as Map<String, dynamic>? ?? {};
            final dur = am['duration'] as int? ?? 0;
            final minutes = dur ~/ 60;
            final seconds = dur % 60;
            return SearchVideoModel(
              id: am['aid'] as int? ?? 0,
              author: '',
              mid: mid,
              title: am['title'] as String? ?? '',
              pic: am['pic'] as String? ?? '',
              play: stat['view'] as int? ?? 0,
              duration: '$minutes:${seconds.toString().padLeft(2, '0')}',
              bvid: am['bvid'] as String? ?? '',
            );
          }).toList(),
        ));
      }

      return MemberSeasonsResult(seasons: seasons, hasMore: hasMore);
    }
    return MemberSeasonsResult(seasons: [], hasMore: false);
  }

  /// Parse archive items from API response list
  List<SearchVideoModel> _parseArchives(List<dynamic> archives, int mid) {
    return archives.map((a) {
      final am = a as Map<String, dynamic>;
      final stat = am['stat'] as Map<String, dynamic>?;
      final dur = am['duration'] as int? ?? 0;
      final minutes = dur ~/ 60;
      final seconds = dur % 60;
      return SearchVideoModel(
        id: am['aid'] as int? ?? 0,
        author: '',
        mid: mid,
        title: am['title'] as String? ?? '',
        pic: am['pic'] as String? ?? '',
        play: stat?['view'] as int? ?? 0,
        duration: '$minutes:${seconds.toString().padLeft(2, '0')}',
        bvid: am['bvid'] as String? ?? '',
      );
    }).toList();
  }

  /// Get one page of videos in a 合集
  Future<CollectionPage> getSeasonDetail({
    required int mid,
    required int seasonId,
    int pn = 1,
    int ps = 30,
  }) async {
    final res = await _provider.getSeasonDetail(
      mid: mid,
      seasonId: seasonId,
      pn: pn,
      ps: ps,
    );
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final archives = data['archives'] as List<dynamic>? ?? [];
      final page = data['page'] as Map<String, dynamic>? ?? {};
      final total = page['total'] as int? ?? 0;
      return CollectionPage(
        items: _parseArchives(archives, mid),
        total: total,
      );
    }
    return CollectionPage(items: [], total: 0);
  }

  /// Get one page of videos in a 系列
  Future<CollectionPage> getSeriesDetail({
    required int mid,
    required int seriesId,
    int pn = 1,
    int ps = 30,
  }) async {
    final res = await _provider.getSeriesDetail(
      mid: mid,
      seriesId: seriesId,
      pn: pn,
      ps: ps,
    );
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final data = res.data['data'] as Map<String, dynamic>;
      final archives = data['archives'] as List<dynamic>? ?? [];
      final page = data['page'] as Map<String, dynamic>? ?? {};
      final total = page['total'] as int? ?? 0;
      return CollectionPage(
        items: _parseArchives(archives, mid),
        total: total,
      );
    }
    return CollectionPage(items: [], total: 0);
  }

  /// Get B站 music zone ranking (rid=3)
  Future<List<SearchVideoModel>> getPartitionRanking() async {
    final params = await WbiSign.makSign({
      'rid': 3,
      'type': 'all',
    });
    final res = await _provider.getPartitionRanking(params);
    if (res.data['code'] == 0 && res.data['data'] != null) {
      final list = res.data['data']['list'] as List<dynamic>? ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final owner = m['owner'] as Map<String, dynamic>? ?? {};
        final stat = m['stat'] as Map<String, dynamic>? ?? {};
        final dur = m['duration'] as int? ?? 0;
        final minutes = dur ~/ 60;
        final seconds = dur % 60;
        return SearchVideoModel(
          id: m['aid'] as int? ?? 0,
          author: owner['name'] as String? ?? '',
          mid: owner['mid'] as int? ?? 0,
          title: m['title'] as String? ?? '',
          description: m['desc'] as String? ?? '',
          pic: m['pic'] as String? ?? '',
          play: stat['view'] as int? ?? 0,
          danmaku: stat['danmaku'] as int? ?? 0,
          duration: '$minutes:${seconds.toString().padLeft(2, '0')}',
          bvid: m['bvid'] as String? ?? '',
        );
      }).toList();
    }
    return [];
  }
}

class MemberSeason {
  final int seasonId;
  final int seriesId;
  final String name;
  final int total;
  final String cover;
  final int category; // 0=合集, 1=系列
  final List<SearchVideoModel> archives;

  MemberSeason({
    required this.seasonId,
    required this.seriesId,
    required this.name,
    required this.total,
    required this.cover,
    required this.category,
    required this.archives,
  });
}

class MemberSeasonsResult {
  final List<MemberSeason> seasons;
  final bool hasMore;

  MemberSeasonsResult({required this.seasons, required this.hasMore});
}

class CollectionPage {
  final List<SearchVideoModel> items;
  final int total;

  bool hasMore(int loadedCount) => loadedCount < total;

  CollectionPage({required this.items, required this.total});
}
