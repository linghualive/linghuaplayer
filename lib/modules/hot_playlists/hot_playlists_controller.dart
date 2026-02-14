import 'dart:developer';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/music/hot_playlist_model.dart';
import '../../data/repositories/music_repository.dart';

class HotPlaylistsController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();

  final playlists = <HotPlaylistModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  static const _pageSize = 12;

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    isLoading.value = true;
    _page = 1;
    hasMore.value = true;
    try {
      final list = await _musicRepo.getHotPlaylists(pn: 1, ps: _pageSize);
      playlists.assignAll(list);
      if (list.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log('Load hot playlists error: $e');
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _page++;
    try {
      final list =
          await _musicRepo.getHotPlaylists(pn: _page, ps: _pageSize);
      playlists.addAll(list);
      if (list.length < _pageSize) hasMore.value = false;
    } catch (e) {
      log('Load more hot playlists error: $e');
    }
    isLoadingMore.value = false;
  }

  void onPlaylistTap(HotPlaylistModel playlist) {
    Get.toNamed(AppRoutes.audioPlaylistDetail, arguments: playlist);
  }
}
