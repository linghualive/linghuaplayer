import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/hot_search_model.dart';
import '../../data/models/search/search_suggest_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/sources/music_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
import '../../shared/utils/app_toast.dart';
import '../../shared/utils/debouncer.dart';

enum SearchState { hot, suggesting, results, empty }

enum NeteaseSearchType { song, artist, album, playlist }

class SearchController extends GetxController {
  // 热门歌手列表
  static const hotArtists = [
    '周杰伦', '林俊杰', '薛之谦', '邓紫棋', '毛不易',
    '陈奕迅', '王菲', '李荣浩', '华晨宇', '许嵩',
    '张学友', '刘德华', 'Beyond', '张国荣',
    '米津玄師', 'YOASOBI', 'IU', 'BLACKPINK',
    'Taylor Swift', 'Ed Sheeran',
  ];


  final _registry = Get.find<MusicSourceRegistry>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
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
    isLoading.value = true;
    try {
      // Use any source that supports hot search
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
      } else {
        // Fallback to direct netease call
        final list = await _neteaseRepo.getHotSearch();
        hotSearchList.assignAll(list);
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> _loadSuggestions(String term) async {
    try {
      // Use the active source if it supports suggestions, otherwise try others
      final activeSource = _registry.activeSource;
      if (activeSource is SearchSuggestCapability) {
        final list = await activeSource.getSearchSuggestions(term);
        suggestions.assignAll(list.map((s) => SearchSuggestModel(
              value: s,
              term: term,
              name: s,
            )));
      } else {
        // Try any source with suggestion capability
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

  void switchNeteaseSearchType(NeteaseSearchType type) {
    if (neteaseSearchType.value == type) return;
    neteaseSearchType.value = type;
    if (currentKeyword.value.isNotEmpty &&
        searchSource.value == 'netease') {
      search(currentKeyword.value);
    }
  }

  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) return;

    await _debugLog('search() called: keyword=$keyword, searchSource=${searchSource.value}');
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
      if (searchSource.value == 'netease' &&
          neteaseSearchType.value != NeteaseSearchType.song) {
        // Multi-type search (artist, album, playlist) still uses
        // NeteaseRepository directly for rich typed results
        await _searchNetease(currentKeyword.value, 0);
      } else {
        // Unified track search via adapter
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
            _neteaseOffset = result.tracks.length;
          } else {
            state.value = SearchState.empty;
          }
        } else {
          state.value = SearchState.empty;
        }
      }
    } catch (e) {
      log('Search error: $e');
      state.value = SearchState.empty;
      AppToast.error('搜索失败: $e');
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
      if (searchSource.value == 'netease' &&
          neteaseSearchType.value != NeteaseSearchType.song) {
        await _searchNetease(currentKeyword.value, _neteaseOffset);
      } else {
        final source = _registry.getSource(searchSource.value);
        if (source != null) {
          final offset = searchSource.value == 'netease'
              ? _neteaseOffset
              : _currentPage * 20;
          final result = await source.searchTracks(
            keyword: currentKeyword.value,
            limit: 30,
            offset: offset,
          );
          if (result.tracks.isNotEmpty) {
            allResults.addAll(result.tracks);
            _hasMore = result.hasMore;
            _neteaseOffset = offset + result.tracks.length;
            _currentPage++;
          } else {
            _hasMore = false;
          }
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

  Future<void> _debugLog(String msg) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/qqmusic_debug.log');
      final ts = DateTime.now().toIso8601String();
      await file.writeAsString('[$ts] $msg\n', mode: FileMode.append);
    } catch (_) {}
  }
}
