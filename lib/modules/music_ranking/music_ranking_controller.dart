import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/music/music_rank_period_model.dart';
import '../../data/models/music/music_rank_song_model.dart';
import '../../data/repositories/music_repository.dart';
import '../player/player_controller.dart';

class MusicRankingController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();

  final periods = <MusicRankPeriodModel>[].obs;
  final songs = <MusicRankSongModel>[].obs;
  final selectedPeriodIndex = 0.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    isLoading.value = true;
    try {
      final list = await _musicRepo.getRankPeriods();
      periods.assignAll(list);
      if (list.isNotEmpty) {
        await _loadSongs(list.first.id);
      }
    } catch (e) {
      log('Load rank periods error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadSongs(int periodId) async {
    _page = 1;
    hasMore.value = true;
    try {
      final list = await _musicRepo.getRankSongs(periodId, pn: 1, ps: 30);
      songs.assignAll(list);
      if (list.length < 30) hasMore.value = false;
    } catch (e) {
      log('Load rank songs error: $e');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || periods.isEmpty) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final periodId = periods[selectedPeriodIndex.value].id;
      final list =
          await _musicRepo.getRankSongs(periodId, pn: _page, ps: 30);
      songs.addAll(list);
      if (list.length < 30) hasMore.value = false;
    } catch (e) {
      log('Load more rank songs error: $e');
    }
    isLoadingMore.value = false;
  }

  void selectPeriod(int index) {
    if (index == selectedPeriodIndex.value) return;
    selectedPeriodIndex.value = index;
    isLoading.value = true;
    _loadSongs(periods[index].id).then((_) {
      isLoading.value = false;
    });
  }

  void playSong(MusicRankSongModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song.toSearchVideoModel());
  }
}
