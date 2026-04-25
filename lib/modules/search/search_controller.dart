import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/hot_search_model.dart';
import '../../data/models/search/search_suggest_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/sources/music_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
import '../../shared/utils/app_toast.dart';
import '../../shared/utils/debouncer.dart';

enum SearchState { hot, suggesting, results, empty }

class SearchController extends GetxController {
  static const hotArtists = [
    '周杰伦', '林俊杰', '薛之谦', '邓紫棋', '毛不易',
    '陈奕迅', '王菲', '李荣浩', '华晨宇', '许嵩',
    '张学友', '刘德华', 'Beyond', '张国荣',
    '米津玄師', 'YOASOBI', 'IU', 'BLACKPINK',
    'Taylor Swift', 'Ed Sheeran',
  ];

  final _registry = Get.find<MusicSourceRegistry>();
  final _storage = Get.find<StorageService>();
  final searchTextController = TextEditingController();
  final focusNode = FocusNode();

  final state = SearchState.hot.obs;
  final hotSearchList = <HotSearchModel>[].obs;
  final suggestions = <SearchSuggestModel>[].obs;
  final searchResults = <SearchVideoModel>[].obs;
  final allResults = <dynamic>[].obs;
  final searchHistory = <String>[].obs;
  final isLoadingMore = false.obs;
  final isLoading = false.obs;
  final currentKeyword = ''.obs;
  final searchSource = 'gdstudio'.obs;
  int _currentPage = 1;
  bool _hasMore = true;

  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  bool _isSearching = false;

  @override
  void onInit() {
    super.onInit();
    loadHotSearch();
    loadSearchHistory();
    searchTextController.addListener(_onSearchTextChanged);

    // Sync with registry's active source
    searchSource.value = _registry.activeSourceId.value;
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
    try {
      final hotSources =
          _registry.getSourcesWithCapability<HotSearchCapability>();
      if (hotSources.isNotEmpty) {
        final keywords = await hotSources.first.getHotSearchKeywords();
        hotSearchList.assignAll(keywords.map((k) => HotSearchModel(
              keyword: k.keyword,
              showName: k.displayName,
              icon: k.iconUrl,
              position: k.position,
            )));
      }
    } catch (_) {}
  }

  Future<void> _loadSuggestions(String term) async {
    try {
      final activeSource = _registry.activeSource;
      if (activeSource is SearchSuggestCapability) {
        final list = await activeSource.getSearchSuggestions(term);
        suggestions.assignAll(list.map((s) => SearchSuggestModel(
              value: s,
              term: term,
              name: s,
            )));
      } else {
        final suggestSources =
            _registry.getSourcesWithCapability<SearchSuggestCapability>();
        if (suggestSources.isNotEmpty) {
          final list = await suggestSources.first.getSearchSuggestions(term);
          suggestions.assignAll(list.map((s) => SearchSuggestModel(
                value: s,
                term: term,
                name: s,
              )));
        }
      }
      if (suggestions.isNotEmpty) {
        state.value = SearchState.suggesting;
      }
    } catch (_) {}
  }

  void switchSource(MusicSource source) {
    final sourceId = source.name;
    if (searchSource.value == sourceId) return;
    searchSource.value = sourceId;
    _registry.activeSourceId.value = sourceId;
    if (currentKeyword.value.isNotEmpty) {
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
    _hasMore = true;
    allResults.clear();
    state.value = SearchState.results;
    isLoading.value = true;
    focusNode.unfocus();

    // Save to history
    _storage.addSearchHistory(keyword.trim());
    loadSearchHistory();

    try {
      final source = _registry.getSource(searchSource.value);
      if (source != null) {
        final result = await source.searchTracks(
          keyword: currentKeyword.value,
          limit: 30,
          offset: 0,
        );
        if (result.tracks.isNotEmpty) {
          allResults.assignAll(result.tracks);
          _hasMore = result.hasMore;
        } else {
          state.value = SearchState.empty;
        }
      } else {
        state.value = SearchState.empty;
      }
    } catch (e) {
      log('Search error: $e');
      state.value = SearchState.empty;
      AppToast.error('搜索失败: $e');
    }
    isLoading.value = false;
    _isSearching = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;

    try {
      final source = _registry.getSource(searchSource.value);
      if (source != null) {
        final offset = _currentPage * 20;
        final result = await source.searchTracks(
          keyword: currentKeyword.value,
          limit: 30,
          offset: offset,
        );
        if (result.tracks.isNotEmpty) {
          allResults.addAll(result.tracks);
          _hasMore = result.hasMore;
          _currentPage++;
        } else {
          _hasMore = false;
        }
      }
    } catch (_) {
      if (searchSource.value == 'bilibili') _currentPage--;
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
