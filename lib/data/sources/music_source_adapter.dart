import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';

/// Core abstraction for a music source. All sources must implement this.
abstract class MusicSourceAdapter {
  /// Unique identifier for this source, e.g. 'bilibili', 'netease'.
  String get sourceId;

  /// Human-readable display name, e.g. 'B站', '网易云音乐'.
  String get displayName;

  /// Whether this source is currently available (e.g. logged in, reachable).
  bool get isAvailable => true;

  /// Search for tracks by keyword.
  Future<SearchResult> searchTracks({
    required String keyword,
    int limit = 30,
    int offset = 0,
  });

  /// Resolve a track to playable stream URLs.
  ///
  /// Returns null if the track cannot be played from this source.
  /// When [videoMode] is true, the adapter should include video streams
  /// if available.
  Future<PlaybackInfo?> resolvePlayback(
    SearchVideoModel track, {
    bool videoMode = false,
  });

  /// Get related / similar tracks for auto-play continuation.
  Future<List<SearchVideoModel>> getRelatedTracks(SearchVideoModel track);
}

// ── Capability Mixins ──────────────────────────────────────────────

/// Source can provide lyrics for a track.
mixin LyricsCapability on MusicSourceAdapter {
  Future<LyricsData?> getLyrics(SearchVideoModel track);
}

/// Source can provide hot search keywords.
mixin HotSearchCapability on MusicSourceAdapter {
  Future<List<HotKeyword>> getHotSearchKeywords();
}

/// Source can provide search suggestions / autocomplete.
mixin SearchSuggestCapability on MusicSourceAdapter {
  Future<List<String>> getSearchSuggestions(String term);
}

/// Source supports playlist browsing.
mixin PlaylistCapability on MusicSourceAdapter {
  Future<List<PlaylistBrief>> getHotPlaylists({int limit = 30});
  Future<PlaylistDetail?> getPlaylistDetail(String id);
}

/// Source supports artist browsing.
mixin ArtistCapability on MusicSourceAdapter {
  Future<ArtistDetail?> getArtistDetail(String id);
  Future<SearchResult> searchArtists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  });
}

/// Source supports album browsing.
mixin AlbumCapability on MusicSourceAdapter {
  Future<AlbumDetail?> getAlbumDetail(String id);
  Future<SearchResult> searchAlbums({
    required String keyword,
    int limit = 30,
    int offset = 0,
  });
}

/// Source supports toplist / ranking charts.
mixin ToplistCapability on MusicSourceAdapter {
  Future<List<ToplistItem>> getToplists();
  Future<PlaylistDetail?> getToplistDetail(String id);
}

/// Source supports login and personalized content.
mixin AuthCapability on MusicSourceAdapter {
  bool get isLoggedIn;
  Future<List<PlaylistBrief>> getUserPlaylists();
  Future<List<SearchVideoModel>> getDailyRecommendations();
}

/// Source supports video playback for some tracks.
mixin VideoCapability on MusicSourceAdapter {
  bool hasVideo(SearchVideoModel track);
}

/// Source supports multi-type search (playlists, albums, artists).
mixin MultiTypeSearchCapability on MusicSourceAdapter {
  Future<List<PlaylistBrief>> searchPlaylists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  });
}
