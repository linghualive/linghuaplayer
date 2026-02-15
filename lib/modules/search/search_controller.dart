import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/hot_search_model.dart';
import '../../data/models/search/search_result_model.dart';
import '../../data/models/search/search_suggest_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../shared/utils/debouncer.dart';

enum SearchState { hot, suggesting, results, empty }

enum NeteaseSearchType { song, artist, album, playlist }

class SearchController extends GetxController {
  final _searchRepo = Get.find<SearchRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _storage = Get.find<StorageService>();
  final searchTextController = TextEditingController();
  final focusNode = FocusNode();

  final state = SearchState.hot.obs;
  final hotSearchList = <HotSearchModel>[].obs;
  final suggestions = <SearchSuggestModel>[].obs;
  final searchResults = <SearchResultModel>[].obs;
  final allResults = <dynamic>[].obs;
  final searchHistory = <String>[].obs;
  final isLoadingMore = false.obs;
  final isLoading = false.obs;
  final currentKeyword = ''.obs;
  final searchSource = MusicSource.netease.obs;
  final neteaseSearchType = NeteaseSearchType.song.obs;
  int _currentPage = 1;
  int _neteaseOffset = 0;
  bool _hasMore = true;

  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  bool _isSearching = false;

  @override
  void onInit() {
    super.onInit();
    loadHotSearch();
    loadSearchHistory();
    searchTextController.addListener(_onSearchTextChanged);
  }

  @override
  void onClose() {
    _debouncer.cancel();
    searchTextController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void loadSearchHistory() {
    searchHistory.assignAll(_storage.getSearchHistory());
  }

  void _onSearchTextChanged() {
    if (_isSearching) return;

    final text = searchTextController.text.trim();
    if (text.isEmpty) {
      state.value = SearchState.hot;
      suggestions.clear();
      return;
    }

    if (!focusNode.hasFocus) return;

    _debouncer.call(() => _loadSuggestions(text));
  }

  Future<void> loadHotSearch() async {
    isLoading.value = true;
    try {
      final list = await _searchRepo.getHotSearch();
      hotSearchList.assignAll(list);
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> _loadSuggestions(String term) async {
    try {
      final list = await _searchRepo.getSuggestions(term);
      suggestions.assignAll(list);
      if (list.isNotEmpty) {
        state.value = SearchState.suggesting;
      }
    } catch (_) {}
  }

  void switchSource(MusicSource source) {
    if (searchSource.value == source) return;
    searchSource.value = source;
    if (currentKeyword.value.isNotEmpty) {
      search(currentKeyword.value);
    }
  }

  void switchNeteaseSearchType(NeteaseSearchType type) {
    if (neteaseSearchType.value == type) return;
    neteaseSearchType.value = type;
    if (currentKeyword.value.isNotEmpty &&
        searchSource.value == MusicSource.netease) {
      search(currentKeyword.value);
    }
  }

  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) return;

    _isSearching = true;
    _debouncer.cancel();

    currentKeyword.value = keyword.trim();
    searchTextController.text = keyword.trim();
    _currentPage = 1;
    _neteaseOffset = 0;
    _hasMore = true;
    allResults.clear();
    state.value = SearchState.results;
    isLoading.value = true;
    focusNode.unfocus();

    // Save to history
    _storage.addSearchHistory(keyword.trim());
    loadSearchHistory();

    try {
      if (searchSource.value == MusicSource.netease) {
        await _searchNetease(currentKeyword.value, 0);
      } else {
        final result = await _searchRepo.searchVideos(
          keyword: currentKeyword.value,
          page: _currentPage,
        );
        if (result != null && result.results.isNotEmpty) {
          allResults.assignAll(result.results);
          _hasMore = result.hasMore;
        } else {
          state.value = SearchState.empty;
        }
      }
    } catch (e) {
      log('Search error: $e');
      state.value = SearchState.empty;
      Get.snackbar('搜索失败', '$e', snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
    _isSearching = false;
  }

  Future<void> _searchNetease(String keyword, int offset) async {
    switch (neteaseSearchType.value) {
      case NeteaseSearchType.song:
        final result = await _neteaseRepo.searchSongs(
          keyword: keyword,
          limit: 30,
          offset: offset,
        );
        if (offset == 0) {
          allResults.assignAll(result.songs);
        } else {
          allResults.addAll(result.songs);
        }
        _neteaseOffset = offset + result.songs.length;
        _hasMore = result.songs.length >= 30;
        if (allResults.isEmpty) state.value = SearchState.empty;
        break;
      case NeteaseSearchType.artist:
        final result = await _neteaseRepo.searchArtists(
          keyword: keyword,
          limit: 30,
          offset: offset,
        );
        if (offset == 0) {
          allResults.assignAll(result.artists);
        } else {
          allResults.addAll(result.artists);
        }
        _neteaseOffset = offset + result.artists.length;
        _hasMore = result.artists.length >= 30;
        if (allResults.isEmpty) state.value = SearchState.empty;
        break;
      case NeteaseSearchType.album:
        final result = await _neteaseRepo.searchAlbums(
          keyword: keyword,
          limit: 30,
          offset: offset,
        );
        if (offset == 0) {
          allResults.assignAll(result.albums);
        } else {
          allResults.addAll(result.albums);
        }
        _neteaseOffset = offset + result.albums.length;
        _hasMore = result.albums.length >= 30;
        if (allResults.isEmpty) state.value = SearchState.empty;
        break;
      case NeteaseSearchType.playlist:
        final result = await _neteaseRepo.searchPlaylists(
          keyword: keyword,
          limit: 30,
          offset: offset,
        );
        if (offset == 0) {
          allResults.assignAll(result.playlists);
        } else {
          allResults.addAll(result.playlists);
        }
        _neteaseOffset = offset + result.playlists.length;
        _hasMore = result.playlists.length >= 30;
        if (allResults.isEmpty) state.value = SearchState.empty;
        break;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;

    try {
      if (searchSource.value == MusicSource.netease) {
        await _searchNetease(currentKeyword.value, _neteaseOffset);
      } else {
        _currentPage++;
        final result = await _searchRepo.searchVideos(
          keyword: currentKeyword.value,
          page: _currentPage,
        );
        if (result != null && result.results.isNotEmpty) {
          allResults.addAll(result.results);
          _hasMore = result.hasMore;
        } else {
          _hasMore = false;
        }
      }
    } catch (_) {
      if (searchSource.value == MusicSource.bilibili) _currentPage--;
    }
    isLoadingMore.value = false;
  }

  void onHotKeywordTap(String keyword) {
    search(keyword);
  }

  void onSuggestionTap(String keyword) {
    search(keyword);
  }

  void removeHistory(String keyword) {
    _storage.removeSearchHistory(keyword);
    loadSearchHistory();
  }

  void clearHistory() {
    _storage.clearSearchHistory();
    searchHistory.clear();
  }

  void clearSearch() {
    searchTextController.clear();
    state.value = SearchState.hot;
    suggestions.clear();
    allResults.clear();
    currentKeyword.value = '';
  }
}
