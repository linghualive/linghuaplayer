import 'dart:developer';

import 'package:get/get.dart';

import '../models/playback_info.dart';
import '../models/search/search_video_model.dart';
import 'music_source_adapter.dart';

/// Central registry for all music source adapters.
///
/// Provides source lookup by ID, capability queries, and cross-source
/// fallback playback resolution.
class MusicSourceRegistry extends GetxService {
  final _sources = <String, MusicSourceAdapter>{};

  /// The currently active source for search (observable).
  final activeSourceId = 'netease'.obs;

  /// Register a source adapter. Overwrites any existing adapter with
  /// the same [sourceId].
  void register(MusicSourceAdapter source) {
    _sources[source.sourceId] = source;
    log('MusicSourceRegistry: registered ${source.sourceId} (${source.displayName})');
  }

  /// Unregister a source adapter.
  void unregister(String sourceId) {
    _sources.remove(sourceId);
  }

  /// Look up a source by its ID.
  MusicSourceAdapter? getSource(String sourceId) => _sources[sourceId];

  /// Look up the source that owns a given track.
  MusicSourceAdapter? getSourceForTrack(SearchVideoModel track) {
    return _sources[track.source.name];
  }

  /// Get the currently active source for search.
  MusicSourceAdapter? get activeSource => _sources[activeSourceId.value];

  /// All registered adapters.
  List<MusicSourceAdapter> get availableSources =>
      _sources.values.where((s) => s.isAvailable).toList();

  /// Get a specific capability from a source, or null if unsupported.
  T? getCapability<T>(String sourceId) {
    final source = _sources[sourceId];
    if (source is T) return source as T;
    return null;
  }

  /// Get all sources that implement a given capability.
  List<T> getSourcesWithCapability<T>() {
    return _sources.values.whereType<T>().toList();
  }

  /// Resolve playback for a track, with optional cross-source fallback.
  ///
  /// Returns a tuple of (PlaybackInfo, SearchVideoModel) because the
  /// track may change if fallback to another source occurred.
  ///
  /// Fallback logic:
  /// 1. Try the track's own source
  /// 2. If [enableFallback] is true and the own source fails,
  ///    search other sources for the same song and try to resolve
  Future<(PlaybackInfo, SearchVideoModel)?> resolvePlaybackWithFallback(
    SearchVideoModel track, {
    bool videoMode = false,
    bool enableFallback = true,
  }) async {
    // 1. Try the track's own source
    final ownSource = getSourceForTrack(track);
    if (ownSource != null) {
      try {
        final info = await ownSource.resolvePlayback(track, videoMode: videoMode);
        if (info != null) return (info, track);
      } catch (e) {
        log('MusicSourceRegistry: ${ownSource.sourceId} resolvePlayback failed: $e');
      }
    }

    if (!enableFallback) return null;

    // 2. Try other sources as fallback
    final keyword = '${track.title} ${track.author}'.trim();
    for (final source in _sources.values) {
      if (source.sourceId == ownSource?.sourceId) continue;

      try {
        final searchResult = await source.searchTracks(
          keyword: keyword,
          limit: 5,
        );
        if (searchResult.tracks.isEmpty) continue;

        final fallbackTrack = searchResult.tracks.first;
        final info = await source.resolvePlayback(
          fallbackTrack,
          videoMode: videoMode,
        );
        if (info != null) {
          log('MusicSourceRegistry: fallback to ${source.sourceId} '
              'for "${track.title}"');
          return (info, fallbackTrack);
        }
      } catch (e) {
        log('MusicSourceRegistry: fallback ${source.sourceId} failed: $e');
      }
    }

    return null;
  }
}
