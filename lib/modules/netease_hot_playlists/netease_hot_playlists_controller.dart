import 'dart:developer';

import 'package:get/get.dart';

import '../../data/repositories/netease_repository.dart';

class NeteaseHotPlaylistsController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();

  final playlists = <NeteasePlaylistBrief>[].obs;
  final categories = <NeteasePlaylistCategory>[].obs;
  final selectedCategory = '全部'.obs;
  final sortOrder = 'hot'.obs; // 'hot' or 'new'
  final isLoading = false.obs;
  final isLoadingMore = false.obs;

  int _offset = 0;
  bool _hasMore = true;
  static const _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    _loadPlaylists();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _neteaseRepo.getPlaylistCategories();
      categories.assignAll(result);
    } catch (e) {
      log('Load playlist categories error: $e');
    }
  }

  Future<void> _loadPlaylists() async {
    isLoading.value = true;
    _offset = 0;
    _hasMore = true;
    playlists.clear();

    try {
      final result = await _neteaseRepo.getHotPlaylistsByCategory(
        cat: selectedCategory.value,
        order: sortOrder.value,
        limit: _pageSize,
        offset: 0,
      );
      playlists.assignAll(result);
      _offset = result.length;
      _hasMore = result.length >= _pageSize;
    } catch (e) {
      log('Load hot playlists error: $e');
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;

    try {
      final result = await _neteaseRepo.getHotPlaylistsByCategory(
        cat: selectedCategory.value,
        order: sortOrder.value,
        limit: _pageSize,
        offset: _offset,
      );
      playlists.addAll(result);
      _offset += result.length;
      _hasMore = result.length >= _pageSize;
    } catch (e) {
      log('Load more hot playlists error: $e');
    }
    isLoadingMore.value = false;
  }

  void switchCategory(String cat) {
    if (selectedCategory.value == cat) return;
    selectedCategory.value = cat;
    _loadPlaylists();
  }

  void switchOrder(String order) {
    if (sortOrder.value == order) return;
    sortOrder.value = order;
    _loadPlaylists();
  }

  Future<void> reload() async {
    await _loadPlaylists();
  }
}
