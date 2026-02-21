import 'dart:developer';

import 'package:get/get.dart';

import '../../app/constants/app_constants.dart';
import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../repositories/lyrics_repository.dart';
import '../repositories/music_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/search_repository.dart';
import 'music_source_adapter.dart';

/// Bilibili music source adapter.
///
/// Thin wrapper around existing SearchRepository, PlayerRepository,
/// MusicRepository, and LyricsRepository.
class BilibiliSourceAdapter extends MusicSourceAdapter
    with LyricsCapability, SearchSuggestCapability, PlaylistCapability {
  final SearchRepository _searchRepo;
  final PlayerRepository _playerRepo;
  final MusicRepository _musicRepo;
  final LyricsRepository _lyricsRepo;

  BilibiliSourceAdapter({
    SearchRepository? searchRepo,
    PlayerRepository? playerRepo,
    MusicRepository? musicRepo,
    LyricsRepository? lyricsRepo,
  })  : _searchRepo = searchRepo ?? Get.find<SearchRepository>(),
        _playerRepo = playerRepo ?? Get.find<PlayerRepository>(),
        _musicRepo = musicRepo ?? Get.find<MusicRepository>(),
        _lyricsRepo = lyricsRepo ?? Get.find<LyricsRepository>();

  static const _bilibiliHeaders = {
    'Referer': AppConstants.referer,
    'User-Agent': AppConstants.pcUserAgent,
  };

  @override
  String get sourceId => 'bilibili';

  @override
  String get displayName => 'B站';

  @override
  Future<SearchResult> searchTracks({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final page = (offset ~/ 20) + 1;
    final result = await _searchRepo.searchVideos(keyword: keyword, page: page);
    if (result == null) {
      return SearchResult(tracks: [], hasMore: false, totalCount: 0);
    }
    return SearchResult(
      tracks: result.results,
      hasMore: result.hasMore,
      totalCount: result.numResults,
    );
  }

  @override
  Future<PlaybackInfo?> resolvePlayback(SearchVideoModel track) async {
    final bvid = track.bvid;
    if (bvid.isEmpty) return null;

    final streams = await _playerRepo.getAudioStreams(bvid);
    if (streams.isEmpty) return null;

    return PlaybackInfo(
      audioStreams: streams
          .map((s) => StreamOption(
                url: s.baseUrl,
                backupUrl: s.backupUrl,
                qualityLabel: s.qualityLabel,
                bandwidth: s.bandwidth,
                codec: s.codecs,
                headers: _bilibiliHeaders,
              ))
          .toList(),
      sourceId: sourceId,
    );
  }

  @override
  Future<List<SearchVideoModel>> getRelatedTracks(SearchVideoModel track) async {
    if (track.bvid.isEmpty) return [];
    return _musicRepo.getRelatedVideos(track.bvid);
  }

  // ── LyricsCapability ──

  @override
  Future<LyricsData?> getLyrics(SearchVideoModel track) async {
    return _lyricsRepo.getLyrics(
      track.title,
      track.author,
      track.duration,
      bvid: track.bvid,
    );
  }

  // ── SearchSuggestCapability ──

  @override
  Future<List<String>> getSearchSuggestions(String term) async {
    final suggestions = await _searchRepo.getSuggestions(term);
    return suggestions.map((s) => s.value).toList();
  }

  // ── PlaylistCapability ──

  @override
  Future<List<PlaylistBrief>> getHotPlaylists({int limit = 30}) async {
    try {
      final playlists = await _musicRepo.getHotPlaylists(ps: limit);
      return playlists
          .map((p) => PlaylistBrief(
                id: p.menuId.toString(),
                sourceId: sourceId,
                name: p.title,
                coverUrl: p.cover,
                playCount: p.playCount,
              ))
          .toList();
    } catch (e) {
      log('BilibiliSourceAdapter.getHotPlaylists error: $e');
      return [];
    }
  }

  @override
  Future<PlaylistDetail?> getPlaylistDetail(String id) async {
    try {
      final menuId = int.tryParse(id);
      if (menuId == null) return null;

      final info = await _musicRepo.getPlaylistInfo(menuId);
      if (info == null) return null;

      final songs = await _musicRepo.getPlaylistSongs(menuId);
      final tracks = songs.map((s) => s.toSearchVideoModel()).toList();

      return PlaylistDetail(
        id: id,
        sourceId: sourceId,
        name: info.title,
        coverUrl: info.cover,
        description: info.intro,
        trackCount: info.songCount,
        tracks: tracks,
      );
    } catch (e) {
      log('BilibiliSourceAdapter.getPlaylistDetail error: $e');
      return null;
    }
  }
}
