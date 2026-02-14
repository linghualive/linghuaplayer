import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/music/hot_playlist_model.dart';
import '../../data/models/music/music_rank_song_model.dart';
import '../../data/models/music/mv_item_model.dart';
import '../../data/repositories/music_repository.dart';
import '../player/player_controller.dart';

class MusicDiscoveryController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();

  final rankSongs = <MusicRankSongModel>[].obs;
  final hotPlaylists = <HotPlaylistModel>[].obs;
  final mvList = <MvItemModel>[].obs;

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
      await Future.wait([
        _loadRankSongs(),
        _loadHotPlaylists(),
        _loadMvList(),
      ]);
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

  void onRankSongTap(MusicRankSongModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song.toSearchVideoModel());
  }

  void onMvTap(MvItemModel mv) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(mv.toSearchVideoModel());
  }
}
