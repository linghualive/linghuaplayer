import 'dart:developer';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/browse_models.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../player/player_controller.dart';

class MusicDiscoveryController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _qqMusicRepo = Get.find<QqMusicRepository>();
  final _storage = Get.find<StorageService>();

  // ── Existing state (kept) ──
  final neteaseNewSongs = <SearchVideoModel>[].obs;
  final dailyRecommendSongs = <SearchVideoModel>[].obs;
  final dailyRecommendPlaylists = <NeteasePlaylistBrief>[].obs;
  final neteaseToplistPreview = <NeteaseToplistItem>[].obs;

  // ── New state ──
  final curatedPlaylists = <PlaylistBrief>[].obs;
  final qqMusicToplistPreview = <ToplistItem>[].obs;
  final selectedGenre = '流行'.obs;
  final genrePlaylists = <NeteasePlaylistBrief>[].obs;
  final isLoadingGenre = false.obs;
  final selectedSingerArea = 200.obs;
  final hotSingers = <QqMusicSingerBrief>[].obs;
  final isLoadingSingers = false.obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final futures = <Future>[
        _loadNeteaseNewSongs(),
        _loadCuratedPlaylists(),
        _loadNeteaseToplistPreview(),
        _loadQqMusicToplistPreview(),
        _loadGenrePlaylists(),
        _loadHotSingers(),
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

  // ── Load methods ──

  Future<void> _loadNeteaseNewSongs() async {
    try {
      final songs = await _neteaseRepo.getTopSongs(type: 0);
      neteaseNewSongs.assignAll(songs.take(10));
    } catch (e) {
      log('Load NetEase new songs error: $e');
    }
  }

  Future<void> _loadCuratedPlaylists() async {
    try {
      final results = await Future.wait([
        _neteaseRepo.getPersonalized(limit: 6),
        _qqMusicRepo.getHotPlaylists(limit: 6),
      ]);

      final neteasePlaylists = (results[0] as List<NeteasePlaylistBrief>)
          .map((p) => PlaylistBrief(
                id: p.id.toString(),
                sourceId: 'netease',
                name: p.name,
                coverUrl: p.coverUrl,
                playCount: p.playCount,
              ))
          .toList();

      final qqPlaylists = results[1] as List<PlaylistBrief>;

      // Interleave: netease, qq, netease, qq, ...
      final merged = <PlaylistBrief>[];
      final maxLen = neteasePlaylists.length > qqPlaylists.length
          ? neteasePlaylists.length
          : qqPlaylists.length;
      for (int i = 0; i < maxLen; i++) {
        if (i < neteasePlaylists.length) merged.add(neteasePlaylists[i]);
        if (i < qqPlaylists.length) merged.add(qqPlaylists[i]);
      }
      curatedPlaylists.assignAll(merged.take(12));
    } catch (e) {
      log('Load curated playlists error: $e');
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

  Future<void> _loadQqMusicToplistPreview() async {
    try {
      final toplists = await _qqMusicRepo.getToplists();
      qqMusicToplistPreview.assignAll(toplists.take(4));
    } catch (e) {
      log('Load QQ Music toplist preview error: $e');
    }
  }

  Future<void> _loadGenrePlaylists() async {
    isLoadingGenre.value = true;
    try {
      final playlists = await _neteaseRepo.getHotPlaylistsByCategory(
        cat: selectedGenre.value,
        limit: 6,
      );
      genrePlaylists.assignAll(playlists);
    } catch (e) {
      log('Load genre playlists error: $e');
    }
    isLoadingGenre.value = false;
  }

  Future<void> _loadHotSingers() async {
    isLoadingSingers.value = true;
    try {
      final singers = await _qqMusicRepo.getSingerList(
        area: selectedSingerArea.value,
      );
      hotSingers.assignAll(singers.take(10));
    } catch (e) {
      log('Load hot singers error: $e');
    }
    isLoadingSingers.value = false;
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

  // ── Interaction methods ──

  void onGenreChanged(String genre) {
    selectedGenre.value = genre;
    _loadGenrePlaylists();
  }

  void onSingerAreaChanged(int area) {
    selectedSingerArea.value = area;
    _loadHotSingers();
  }

  void navigateToPlaylist(PlaylistBrief playlist) {
    if (playlist.sourceId == 'qqmusic') {
      Get.toNamed(
        AppRoutes.qqMusicPlaylistDetail,
        arguments: playlist.id,
      );
    } else {
      Get.toNamed(
        AppRoutes.neteasePlaylistDetail,
        arguments: NeteasePlaylistBrief(
          id: int.tryParse(playlist.id) ?? 0,
          name: playlist.name,
          coverUrl: playlist.coverUrl,
          playCount: playlist.playCount,
        ),
      );
    }
  }

  void onSingerTap(QqMusicSingerBrief singer) {
    Get.toNamed(AppRoutes.qqMusicArtistDetail, arguments: singer);
  }

  void onNeteaseNewSongTap(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song);
  }

  void onDailyRecommendSongTap(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song);
  }
}
