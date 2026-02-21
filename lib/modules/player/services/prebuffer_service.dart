import 'dart:developer';

/// Pre-resolves the URL for the next track to enable gapless transitions.
///
/// When the current track approaches completion, this service resolves
/// the playback URL for the next track ahead of time, eliminating the
/// delay between tracks.
class PrebufferService {
  String? _prebufferedUrl;
  int _generation = 0;

  /// Whether a track URL has been pre-resolved and is ready.
  bool get hasPrebufferedTrack => _prebufferedUrl != null;

  /// The pre-resolved URL, if available.
  String? get prebufferedUrl => _prebufferedUrl;

  /// Pre-resolve the URL for the next track.
  ///
  /// [resolveUrl] should return the playback URL for the next track.
  /// If a previous prebuffer is in progress, it will be cancelled.
  Future<void> prebufferNext({
    required Future<String> Function() resolveUrl,
  }) async {
    final gen = ++_generation;

    try {
      final url = await resolveUrl();

      // Only apply if this is still the latest prebuffer request
      if (gen == _generation) {
        _prebufferedUrl = url;
        log('PrebufferService: pre-resolved URL ready');
      }
    } catch (e) {
      log('PrebufferService: failed to pre-resolve: $e');
      if (gen == _generation) {
        _prebufferedUrl = null;
      }
    }
  }

  /// Consume the pre-resolved URL (returns it and clears state).
  String? consumePrebuffered() {
    final url = _prebufferedUrl;
    _prebufferedUrl = null;
    return url;
  }

  /// Cancel any pending prebuffer and clear state.
  void cancel() {
    _generation++;
    _prebufferedUrl = null;
  }
}
