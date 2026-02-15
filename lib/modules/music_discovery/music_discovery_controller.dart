import 'dart:developer';

import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/music/hot_playlist_model.dart';
import '../../data/models/music/music_rank_song_model.dart';
import '../../data/models/music/mv_item_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../player/player_controller.dart';

class MusicDiscoveryController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _storage = Get.find<StorageService>();

  final rankSongs = <MusicRankSongModel>[].obs;
  final hotPlaylists = <HotPlaylistModel>[].obs;
  final mvList = <MvItemModel>[].obs;
  final neteaseNewSongs = <SearchVideoModel>[].obs;
  final neteaseRecommendPlaylists = <NeteasePlaylistBrief>[].obs;

  // Personalized (requires NetEase login)
  final dailyRecommendSongs = <SearchVideoModel>[].obs;
  final dailyRecommendPlaylists = <NeteasePlaylistBrief>[].obs;

  // NetEase toplist (top 4 for preview)
  final neteaseToplistPreview = <NeteaseToplistItem>[].obs;

  // B站 music zone ranking
  final biliMusicRanking = <SearchVideoModel>[].obs;

  final isLoading = false.obs;
  final rankTitle = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final futures = <Future>[
        _loadRankSongs(),
        _loadHotPlaylists(),
        _loadMvList(),
        _loadNeteaseNewSongs(),
        _loadNeteaseRecommendPlaylists(),
        _loadNeteaseToplistPreview(),
        _loadBiliMusicRanking(),
      ];
      if (_storage.isNeteaseLoggedIn) {
        futures.add(_loadDailyRecommendSongs());
        futures.add(_loadDailyRecommendPlaylists());
      } else {
        dailyRecommendSongs.clear();
        dailyRecommendPlaylists.clear();
      }
      await Future.wait(futures);
    } catch (e) {
      log('Music discovery load error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadRankSongs() async {
    try {
      final periods = await _musicRepo.getRankPeriods();
      if (periods.isEmpty) return;

      final latestPeriod = periods.first;
      rankTitle.value = latestPeriod.name;

      final songs =
          await _musicRepo.getRankSongs(latestPeriod.id, ps: 10);
      rankSongs.assignAll(songs);
    } catch (e) {
      log('Load rank songs error: $e');
    }
  }

  Future<void> _loadHotPlaylists() async {
    try {
      final playlists = await _musicRepo.getHotPlaylists(ps: 6);
      hotPlaylists.assignAll(playlists);
    } catch (e) {
      log('Load hot playlists error: $e');
    }
  }

  Future<void> _loadMvList() async {
    try {
      final mvs = await _musicRepo.getMvList(ps: 10, order: 0);
      mvList.assignAll(mvs);
    } catch (e) {
      log('Load MV list error: $e');
    }
  }

  Future<void> _loadNeteaseNewSongs() async {
    try {
      final songs = await _neteaseRepo.getTopSongs(type: 0);
      neteaseNewSongs.assignAll(songs.take(10));
    } catch (e) {
      log('Load NetEase new songs error: $e');
    }
  }

  Future<void> _loadNeteaseRecommendPlaylists() async {
    try {
      final playlists = await _neteaseRepo.getPersonalized(limit: 6);
      neteaseRecommendPlaylists.assignAll(playlists);
    } catch (e) {
      log('Load NetEase recommend playlists error: $e');
    }
  }

  Future<void> _loadDailyRecommendSongs() async {
    try {
      final songs = await _neteaseRepo.getDailyRecommendSongs();
      dailyRecommendSongs.assignAll(songs.take(10));
    } catch (e) {
      log('Load daily recommend songs error: $e');
    }
  }

  Future<void> _loadDailyRecommendPlaylists() async {
    try {
      final playlists = await _neteaseRepo.getDailyRecommendPlaylists();
      dailyRecommendPlaylists.assignAll(playlists.take(6));
    } catch (e) {
      log('Load daily recommend playlists error: $e');
    }
  }

  Future<void> _loadNeteaseToplistPreview() async {
    try {
      final toplists = await _neteaseRepo.getToplist();
      neteaseToplistPreview.assignAll(toplists.take(4));
    } catch (e) {
      log('Load NetEase toplist preview error: $e');
    }
  }

  Future<void> _loadBiliMusicRanking() async {
    try {
      final videos = await _musicRepo.getPartitionRanking();
      biliMusicRanking.assignAll(videos.take(10));
    } catch (e) {
      log('Load B站 music ranking error: $e');
    }
  }

  void onNeteaseNewSongTap(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song);
  }

  void onDailyRecommendSongTap(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song);
  }

  void onRankSongTap(MusicRankSongModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song.toSearchVideoModel());
  }

  void onMvTap(MvItemModel mv) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(mv.toSearchVideoModel());
  }

  void onBiliMusicRankingTap(SearchVideoModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video);
  }
}
