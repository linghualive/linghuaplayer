import 'dart:async';
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

  // ── Circuit Breaker ──
  // Track consecutive failures per source to skip unreliable sources temporarily
  final _sourceFailures = <String, int>{};
  final _sourceCircuitOpenUntil = <String, DateTime>{};
  static const _circuitBreakerThreshold = 3;
  static const _circuitBreakerCooldown = Duration(seconds: 60);

  bool _isCircuitOpen(String sourceId) {
    final openUntil = _sourceCircuitOpenUntil[sourceId];
    if (openUntil == null) return false;
    if (DateTime.now().isAfter(openUntil)) {
      // Cooldown expired, reset
      _sourceCircuitOpenUntil.remove(sourceId);
      _sourceFailures.remove(sourceId);
      return false;
    }
    return true;
  }

  void _recordSourceSuccess(String sourceId) {
    _sourceFailures.remove(sourceId);
    _sourceCircuitOpenUntil.remove(sourceId);
  }

  void _recordSourceFailure(String sourceId) {
    final count = (_sourceFailures[sourceId] ?? 0) + 1;
    _sourceFailures[sourceId] = count;
    if (count >= _circuitBreakerThreshold) {
      _sourceCircuitOpenUntil[sourceId] =
          DateTime.now().add(_circuitBreakerCooldown);
      log('MusicSourceRegistry: circuit breaker OPEN for $sourceId '
          '(${_circuitBreakerCooldown.inSeconds}s cooldown)');
    }
  }

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
  static const _resolveTimeout = Duration(seconds: 8);
  static const _totalResolveTimeout = Duration(seconds: 12);

  Future<(PlaybackInfo, SearchVideoModel)?> resolvePlaybackWithFallback(
    SearchVideoModel track, {
    bool enableFallback = true,
    String? preferredSourceId,
  }) async {
    try {
      return await _resolvePlaybackImpl(
        track,
        enableFallback: enableFallback,
        preferredSourceId: preferredSourceId,
      ).timeout(_totalResolveTimeout);
    } on TimeoutException {
      log('MusicSourceRegistry: total resolve timeout for "${track.title}"');
      return null;
    }
  }

  Future<(PlaybackInfo, SearchVideoModel)?> _resolvePlaybackImpl(
    SearchVideoModel track, {
    bool enableFallback = true,
    String? preferredSourceId,
  }) async {
    final keyword = '${track.title} ${track.author}'.trim();

    // 1. Try preferred source first (e.g. gdstudio for search/recommendation)
    if (preferredSourceId != null && !_isCircuitOpen(preferredSourceId)) {
      final preferredSource = getSource(preferredSourceId);
      if (preferredSource != null) {
        // If the track already belongs to this source, resolve directly
        if (track.source.name == preferredSourceId) {
          try {
            final info = await preferredSource
                .resolvePlayback(track)
                .timeout(_resolveTimeout);
            if (info != null) {
              _recordSourceSuccess(preferredSourceId);
              return (info, track);
            }
            _recordSourceFailure(preferredSourceId);
          } catch (e) {
            _recordSourceFailure(preferredSourceId);
            log('MusicSourceRegistry: preferred source $preferredSourceId '
                'direct resolve failed: $e');
          }
        }

        // Otherwise search and resolve
        if (!_isCircuitOpen(preferredSourceId)) {
          try {
            final searchResult = await preferredSource
                .searchTracks(keyword: keyword, limit: 5)
                .timeout(_resolveTimeout);
            if (searchResult.tracks.isNotEmpty) {
              final preferredTrack = searchResult.tracks.first;
              final info = await preferredSource
                  .resolvePlayback(preferredTrack)
                  .timeout(_resolveTimeout);
              if (info != null) {
                _recordSourceSuccess(preferredSourceId);
                log('MusicSourceRegistry: resolved via preferred source '
                    '$preferredSourceId for "${track.title}"');
                return (info, preferredTrack);
              }
            }
            _recordSourceFailure(preferredSourceId);
          } catch (e) {
            _recordSourceFailure(preferredSourceId);
            log('MusicSourceRegistry: preferred source $preferredSourceId '
                'search failed: $e');
          }
        }
      }
    }

    // 2. Try the track's own source
    final ownSource = getSourceForTrack(track);
    if (ownSource != null &&
        ownSource.sourceId != preferredSourceId &&
        !_isCircuitOpen(ownSource.sourceId)) {
      try {
        final info = await ownSource
            .resolvePlayback(track)
            .timeout(_resolveTimeout);
        if (info != null) {
          _recordSourceSuccess(ownSource.sourceId);
          return (info, track);
        }
        _recordSourceFailure(ownSource.sourceId);
      } catch (e) {
        _recordSourceFailure(ownSource.sourceId);
        log('MusicSourceRegistry: ${ownSource.sourceId} resolvePlayback failed: $e');
      }
    }

    if (!enableFallback) return null;

    // 3. Try other sources as fallback (first-success via Completer)
    final triedSources = <String>{
      if (preferredSourceId != null) preferredSourceId,
      if (ownSource != null) ownSource.sourceId,
    };

    final fallbackSources = _sources.values
        .where((s) =>
            !triedSources.contains(s.sourceId) &&
            !_isCircuitOpen(s.sourceId))
        .toList();

    if (fallbackSources.isNotEmpty) {
      final completer = Completer<(PlaybackInfo, SearchVideoModel)?>();
      int remaining = fallbackSources.length;

      for (final source in fallbackSources) {
        _tryResolveFromSource(source, keyword, track).then((result) {
          if (result != null && !completer.isCompleted) {
            _recordSourceSuccess(source.sourceId);
            completer.complete(result);
          } else {
            if (result == null) _recordSourceFailure(source.sourceId);
            remaining--;
            if (remaining <= 0 && !completer.isCompleted) {
              completer.complete(null);
            }
          }
        }).catchError((e) {
          _recordSourceFailure(source.sourceId);
          remaining--;
          if (remaining <= 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        });
      }

      return await completer.future;
    }

    return null;
  }

  Future<(PlaybackInfo, SearchVideoModel)?> _tryResolveFromSource(
    MusicSourceAdapter source,
    String keyword,
    SearchVideoModel originalTrack,
  ) async {
    try {
      final searchResult = await source
          .searchTracks(keyword: keyword, limit: 5)
          .timeout(_resolveTimeout);
      if (searchResult.tracks.isEmpty) return null;

      final fallbackTrack = searchResult.tracks.first;
      final info = await source
          .resolvePlayback(fallbackTrack)
          .timeout(_resolveTimeout);
      if (info != null) {
        log('MusicSourceRegistry: fallback to ${source.sourceId} '
            'for "${originalTrack.title}"');
        return (info, fallbackTrack);
      }
    } catch (e) {
      log('MusicSourceRegistry: fallback ${source.sourceId} failed: $e');
    }
    return null;
  }
}
