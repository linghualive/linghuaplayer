import 'dart:developer';

import 'package:get/get.dart';

import '../../core/http/qqmusic_http_client.dart';
import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../repositories/qqmusic_repository.dart';
import 'music_source_adapter.dart';

/// QQ Music source adapter.
///
/// Thin wrapper around QqMusicRepository, implementing the full
/// MusicSourceAdapter interface with all applicable capabilities.
class QqMusicSourceAdapter extends MusicSourceAdapter
    with
        LyricsCapability,
        HotSearchCapability,
        SearchSuggestCapability,
        PlaylistCapability,
        ArtistCapability,
        AlbumCapability,
        ToplistCapability,
        AuthCapability,
        MultiTypeSearchCapability {
  final QqMusicRepository _repo;

  QqMusicSourceAdapter({QqMusicRepository? repository})
      : _repo = repository ?? Get.find<QqMusicRepository>();

  @override
  String get sourceId => 'qqmusic';

  @override
  String get displayName => 'QQ音乐';

  // ── Core: searchTracks ──

  @override
  Future<SearchResult> searchTracks({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    return _repo.searchSongs(keyword: keyword, limit: limit, offset: offset);
  }

  // ── Core: resolvePlayback ──

  @override
  Future<PlaybackInfo?> resolvePlayback(
    SearchVideoModel track, {
    bool videoMode = false,
  }) async {
    final songmid = track.bvid; // songmid stored in bvid field
    if (songmid.isEmpty) return null;

    // Try multiple qualities, highest first
    final qualities = ['flac', '320', 'm4a', '128'];
    final streams = <StreamOption>[];

    for (final quality in qualities) {
      try {
        final url = await _repo.getPlayUrl(songmid, quality: quality);
        if (url != null) {
          streams.add(StreamOption(
            url: url,
            qualityLabel: _qualityLabel(quality),
            headers: const {},
          ));
        }
      } catch (e) {
        log('QqMusicSourceAdapter: quality $quality failed for $songmid: $e');
      }
    }

    if (streams.isEmpty) return null;

    return PlaybackInfo(
      audioStreams: streams,
      sourceId: sourceId,
    );
  }

  // ── Core: getRelatedTracks ──

  @override
  Future<List<SearchVideoModel>> getRelatedTracks(SearchVideoModel track) async {
    if (track.author.isEmpty) return [];
    final result = await _repo.searchSongs(
      keyword: '${track.author} 歌曲',
      limit: 20,
    );
    return result.tracks.where((s) => s.id != track.id).toList();
  }

  // ── LyricsCapability ──

  @override
  Future<LyricsData?> getLyrics(SearchVideoModel track) async {
    final songmid = track.bvid;
    if (songmid.isEmpty) return null;
    return _repo.getLyrics(songmid);
  }

  // ── HotSearchCapability ──

  @override
  Future<List<HotKeyword>> getHotSearchKeywords() async {
    return _repo.getHotkeys();
  }

  // ── SearchSuggestCapability ──

  @override
  Future<List<String>> getSearchSuggestions(String term) async {
    return _repo.getSearchSuggestions(term);
  }

  // ── PlaylistCapability ──

  @override
  Future<List<PlaylistBrief>> getHotPlaylists({int limit = 30}) async {
    return _repo.getHotPlaylists(limit: limit);
  }

  @override
  Future<PlaylistDetail?> getPlaylistDetail(String id) async {
    return _repo.getPlaylistDetail(id);
  }

  // ── ArtistCapability ──

  @override
  Future<ArtistDetail?> getArtistDetail(String id) async {
    return _repo.getArtistDetail(id);
  }

  @override
  Future<SearchResult> searchArtists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    // QQ Music search supports catZhida=2 for artists, but we use
    // the generic search and return empty tracks (consistent with Netease)
    return SearchResult(tracks: [], hasMore: false, totalCount: 0);
  }

  // ── AlbumCapability ──

  @override
  Future<AlbumDetail?> getAlbumDetail(String id) async {
    return _repo.getAlbumDetail(id);
  }

  @override
  Future<SearchResult> searchAlbums({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    return SearchResult(tracks: [], hasMore: false, totalCount: 0);
  }

  // ── ToplistCapability ──

  @override
  Future<List<ToplistItem>> getToplists() async {
    return _repo.getToplists();
  }

  @override
  Future<PlaylistDetail?> getToplistDetail(String id) async {
    final topId = int.tryParse(id);
    if (topId == null) return null;
    return _repo.getToplistDetail(topId);
  }

  // ── AuthCapability ──

  @override
  bool get isLoggedIn => QqMusicHttpClient.instance.isLoggedIn;

  @override
  Future<List<PlaylistBrief>> getUserPlaylists() async {
    final uin = QqMusicHttpClient.instance.loginUin;
    if (uin == '0' || uin.isEmpty) return [];
    final playlists = await _repo.getUserPlaylists(uin);
    return playlists.map((p) => PlaylistBrief(
      id: p.id,
      sourceId: 'qqmusic',
      name: p.name,
      coverUrl: p.coverUrl,
      playCount: p.songCount,
    )).toList();
  }

  @override
  Future<List<SearchVideoModel>> getDailyRecommendations() async => [];

  // ── MultiTypeSearchCapability ──

  @override
  Future<List<PlaylistBrief>> searchPlaylists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    // Not yet implemented; return empty
    return [];
  }

  // ── Helpers ──

  static String _qualityLabel(String quality) {
    switch (quality) {
      case 'flac':
        return 'FLAC 无损';
      case 'ape':
        return 'APE 无损';
      case '320':
        return '320kbps';
      case 'm4a':
        return 'M4A HQ';
      case '128':
      default:
        return '128kbps';
    }
  }
}
