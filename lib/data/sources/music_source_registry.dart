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
  final activeSourceId = 'gdstudio'.obs;

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
  /// When [preferredSourceId] is set, try that source first (via search)
  /// before the track's own source. This is used to route search/recommendation
  /// playback through GD Studio by default.
  ///
  /// Fallback logic:
  /// 1. If [preferredSourceId] is set, search and resolve via that source
  /// 2. Try the track's own source
  /// 3. If [enableFallback] is true and both fail,
  ///    search other sources for the same song and try to resolve
  Future<(PlaybackInfo, SearchVideoModel)?> resolvePlaybackWithFallback(
    SearchVideoModel track, {
    bool enableFallback = true,
    String? preferredSourceId,
  }) async {
    final keyword = '${track.title} ${track.author}'.trim();

    // 1. Try preferred source first (e.g. gdstudio for search/recommendation)
    if (preferredSourceId != null) {
      final preferredSource = getSource(preferredSourceId);
      if (preferredSource != null) {
        // If the track already belongs to this source, resolve directly
        if (track.source.name == preferredSourceId) {
          try {
            final info = await preferredSource.resolvePlayback(track);
            if (info != null) return (info, track);
          } catch (e) {
            log('MusicSourceRegistry: preferred source $preferredSourceId '
                'direct resolve failed: $e');
          }
        }

        // Otherwise search and resolve
        try {
          final searchResult = await preferredSource.searchTracks(
            keyword: keyword,
            limit: 5,
          );
          if (searchResult.tracks.isNotEmpty) {
            final preferredTrack = searchResult.tracks.first;
            final info = await preferredSource.resolvePlayback(preferredTrack);
            if (info != null) {
              log('MusicSourceRegistry: resolved via preferred source '
                  '$preferredSourceId for "${track.title}"');
              return (info, preferredTrack);
            }
          }
        } catch (e) {
          log('MusicSourceRegistry: preferred source $preferredSourceId '
              'search failed: $e');
        }
      }
    }

    // 2. Try the track's own source
    final ownSource = getSourceForTrack(track);
    if (ownSource != null &&
        ownSource.sourceId != preferredSourceId) {
      try {
        final info = await ownSource.resolvePlayback(track);
        if (info != null) return (info, track);
      } catch (e) {
        log('MusicSourceRegistry: ${ownSource.sourceId} resolvePlayback failed: $e');
      }
    }

    if (!enableFallback) return null;

    // 3. Try other sources as fallback
    final triedSources = <String>{
      if (preferredSourceId != null) preferredSourceId,
      if (ownSource != null) ownSource.sourceId,
    };

    for (final source in _sources.values) {
      if (triedSources.contains(source.sourceId)) continue;

      try {
        final searchResult = await source.searchTracks(
          keyword: keyword,
          limit: 5,
        );
        if (searchResult.tracks.isEmpty) continue;

        final fallbackTrack = searchResult.tracks.first;
        final info = await source.resolvePlayback(fallbackTrack);
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
