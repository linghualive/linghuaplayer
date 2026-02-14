import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/music/mv_item_model.dart';
import '../../data/repositories/music_repository.dart';
import '../player/player_controller.dart';

class MvListController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();

  final mvList = <MvItemModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadMvList();
  }

  Future<void> loadMvList() async {
    isLoading.value = true;
    _page = 1;
    hasMore.value = true;
    try {
      final list = await _musicRepo.getMvList(pn: 1, ps: _pageSize);
      mvList.assignAll(list);
      if (list.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log('Load MV list error: $e');
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final list = await _musicRepo.getMvList(pn: _page, ps: _pageSize);
      mvList.addAll(list);
      if (list.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log('Load more MV list error: $e');
    }
    isLoadingMore.value = false;
  }

  void onMvTap(MvItemModel mv) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(mv.toSearchVideoModel());
  }
}
