import 'package:get/get.dart';

import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../repositories/gdstudio_repository.dart';
import 'music_source_adapter.dart';

/// GD Studio aggregated music source adapter.
///
/// Uses the GD Studio Music API (music-api.gdstudio.xyz) which aggregates
/// multiple backend sources (netease, kuwo, joox, bilibili, etc.).
/// Defaults to the highest available audio quality (br=999).
class GdStudioSourceAdapter extends MusicSourceAdapter with LyricsCapability {
  final GdStudioRepository _repo;

  GdStudioSourceAdapter({GdStudioRepository? repository})
      : _repo = repository ?? Get.find<GdStudioRepository>();

  @override
  String get sourceId => 'gdstudio';

  @override
  String get displayName => 'GD音乐台';

  // ── Core: searchTracks ──

  @override
  Future<SearchResult> searchTracks({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    return _repo.searchSongs(
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
  }

  // ── Core: resolvePlayback ──

  @override
  Future<PlaybackInfo?> resolvePlayback(
    SearchVideoModel track, {
    bool videoMode = false,
  }) async {
    return _repo.resolvePlayback(track);
  }

  // ── Core: getRelatedTracks ──

  @override
  Future<List<SearchVideoModel>> getRelatedTracks(
      SearchVideoModel track) async {
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
    if (track.description.isNotEmpty && track.description.length > 1) {
      keywords.add(track.description);
    }

    final keyword = (keywords..shuffle()).first;
    final result = await _repo.searchSongs(keyword: keyword, limit: 20);
    final filtered = result.tracks.where((s) => s.id != track.id).toList();
    filtered.shuffle();
    return filtered;
  }

  // ── LyricsCapability ──

  @override
  Future<LyricsData?> getLyrics(SearchVideoModel track) async {
    return _repo.getLyrics(track);
  }
}
