import 'dart:developer';

import 'package:get/get.dart';

import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../repositories/lyrics_repository.dart';
import '../repositories/netease_repository.dart';
import 'music_source_adapter.dart';

/// NetEase Cloud Music source adapter.
///
/// Thin wrapper around the existing NeteaseRepository and LyricsRepository.
class NeteaseSourceAdapter extends MusicSourceAdapter
    with
        LyricsCapability,
        HotSearchCapability,
        PlaylistCapability,
        ArtistCapability,
        AlbumCapability,
        ToplistCapability,
        AuthCapability,
        MultiTypeSearchCapability {
  final NeteaseRepository _neteaseRepo;
  final LyricsRepository _lyricsRepo;

  NeteaseSourceAdapter({
    NeteaseRepository? neteaseRepo,
    LyricsRepository? lyricsRepo,
  })  : _neteaseRepo = neteaseRepo ?? Get.find<NeteaseRepository>(),
        _lyricsRepo = lyricsRepo ?? Get.find<LyricsRepository>();

  @override
  String get sourceId => 'netease';

  @override
  String get displayName => '网易云音乐';

  @override
  Future<SearchResult> searchTracks({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await _neteaseRepo.searchSongs(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
    return SearchResult(
      tracks: result.songs,
      hasMore: result.songs.length >= limit,
      totalCount: result.songCount,
    );
  }

  @override
  Future<PlaybackInfo?> resolvePlayback(
    SearchVideoModel track, {
    bool videoMode = false,
  }) async {
    final url = await _neteaseRepo.getSongUrl(track.id);
    if (url == null || url.isEmpty) return null;

    // NetEase audio streams don't require special headers
    return PlaybackInfo(
      audioStreams: [
        StreamOption(
          url: url,
          qualityLabel: '网易云',
          headers: const {},
        ),
      ],
      sourceId: sourceId,
    );
  }

  @override
  Future<List<SearchVideoModel>> getRelatedTracks(SearchVideoModel track) async {
    if (track.author.isEmpty && track.title.isEmpty) return [];

    // Use varied search keywords for diversity
    final keywords = <String>[];
    if (track.author.isNotEmpty) {
      keywords.add(track.author);
      keywords.add('${track.author} 热门');
    }
    if (track.title.isNotEmpty) {
      keywords.add(track.title);
    }
    // Album as keyword
    if (track.description.isNotEmpty && track.description.length > 1) {
      keywords.add(track.description);
    }

    // Pick a random keyword for variety
    final keyword = (keywords..shuffle()).first;
    final result = await _neteaseRepo.searchSongs(
      keyword: keyword,
      limit: 20,
    );
    final filtered = result.songs.where((s) => s.id != track.id).toList();
    filtered.shuffle();
    return filtered;
  }

  // ── LyricsCapability ──

  @override
  Future<LyricsData?> getLyrics(SearchVideoModel track) async {
    return _lyricsRepo.getNeteaseLyrics(track.id);
  }

  // ── HotSearchCapability ──

  @override
  Future<List<HotKeyword>> getHotSearchKeywords() async {
    final list = await _neteaseRepo.getHotSearch();
    return list
        .map((h) => HotKeyword(
              keyword: h.keyword,
              displayName: h.showName,
              iconUrl: h.icon,
              position: h.position,
            ))
        .toList();
  }

  // ── PlaylistCapability ──

  @override
  Future<List<PlaylistBrief>> getHotPlaylists({int limit = 30}) async {
    try {
      final playlists =
          await _neteaseRepo.getHotPlaylistsByCategory(limit: limit);
      return playlists
          .map((p) => PlaylistBrief(
                id: p.id.toString(),
                sourceId: sourceId,
                name: p.name,
                coverUrl: p.coverUrl,
                playCount: p.playCount,
              ))
          .toList();
    } catch (e) {
      log('NeteaseSourceAdapter.getHotPlaylists error: $e');
      return [];
    }
  }

  @override
  Future<PlaylistDetail?> getPlaylistDetail(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final detail = await _neteaseRepo.getPlaylistDetail(intId);
    if (detail == null) return null;

    return PlaylistDetail(
      id: id,
      sourceId: sourceId,
      name: detail.name,
      coverUrl: detail.coverUrl,
      description: detail.description,
      playCount: detail.playCount,
      trackCount: detail.trackCount,
      creatorName: detail.creatorName,
      tracks: detail.tracks,
    );
  }

  // ── ArtistCapability ──

  @override
  Future<ArtistDetail?> getArtistDetail(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final detail = await _neteaseRepo.getArtistDetail(intId);
    if (detail == null) return null;

    return ArtistDetail(
      id: id,
      sourceId: sourceId,
      name: detail.name,
      picUrl: detail.picUrl,
      briefDesc: detail.briefDesc,
      musicSize: detail.musicSize,
      albumSize: detail.albumSize,
      hotSongs: detail.hotSongs,
    );
  }

  @override
  Future<SearchResult> searchArtists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await _neteaseRepo.searchArtists(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
    // Return artists as SearchResult (tracks will be empty; callers use
    // the raw NeteaseArtistSearchResult via the repository for now)
    return SearchResult(
      tracks: [],
      hasMore: result.artists.length >= limit,
      totalCount: result.artistCount,
    );
  }

  // ── AlbumCapability ──

  @override
  Future<AlbumDetail?> getAlbumDetail(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;

    final detail = await _neteaseRepo.getAlbumDetail(intId);
    if (detail == null) return null;

    return AlbumDetail(
      id: id,
      sourceId: sourceId,
      name: detail.name,
      picUrl: detail.picUrl,
      artistName: detail.artistName,
      publishTime: detail.publishTime,
      description: detail.description,
      tracks: detail.tracks,
    );
  }

  @override
  Future<SearchResult> searchAlbums({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await _neteaseRepo.searchAlbums(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
    return SearchResult(
      tracks: [],
      hasMore: result.albums.length >= limit,
      totalCount: result.albumCount,
    );
  }

  // ── ToplistCapability ──

  @override
  Future<List<ToplistItem>> getToplists() async {
    final items = await _neteaseRepo.getToplist();
    return items
        .map((t) => ToplistItem(
              id: t.id.toString(),
              sourceId: sourceId,
              name: t.name,
              coverUrl: t.coverUrl,
              updateFrequency: t.updateFrequency,
              trackPreviews: t.trackPreviews,
            ))
        .toList();
  }

  @override
  Future<PlaylistDetail?> getToplistDetail(String id) async {
    return getPlaylistDetail(id);
  }

  // ── AuthCapability ──

  @override
  bool get isLoggedIn {
    // Delegate to existing auth state; for now, check if account info is cached
    // This will be refined when auth state is centralized
    return false;
  }

  @override
  Future<List<PlaylistBrief>> getUserPlaylists() async {
    // Requires userId; this will be wired up when auth is integrated
    return [];
  }

  @override
  Future<List<SearchVideoModel>> getDailyRecommendations() async {
    return _neteaseRepo.getDailyRecommendSongs();
  }

  // ── MultiTypeSearchCapability ──

  @override
  Future<List<PlaylistBrief>> searchPlaylists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await _neteaseRepo.searchPlaylists(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
    return result.playlists
        .map((p) => PlaylistBrief(
              id: p.id.toString(),
              sourceId: sourceId,
              name: p.name,
              coverUrl: p.coverUrl,
              playCount: p.playCount,
            ))
        .toList();
  }
}
