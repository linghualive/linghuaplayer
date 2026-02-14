import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/hot_search_model.dart';
import '../../data/models/search/search_result_model.dart';
import '../../data/models/search/search_suggest_model.dart';
import '../../data/repositories/search_repository.dart';
import '../../shared/utils/debouncer.dart';

enum SearchState { hot, suggesting, results, empty }

class SearchController extends GetxController {
  final _searchRepo = Get.find<SearchRepository>();
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
    } catch (_) {
      state.value = SearchState.empty;
    }
    isLoading.value = false;
    _isSearching = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    _currentPage++;

    try {
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
    } catch (_) {
      _currentPage--;
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
