/// Manages crossfade transitions between tracks.
///
/// Calculates volume curves for the current (fading out) and next
/// (fading in) tracks based on playback position relative to track end.
class CrossfadeService {
  static const _maxDuration = Duration(seconds: 12);

  Duration _crossfadeDuration = Duration.zero;

  /// The crossfade duration. Clamped to 0-12 seconds.
  Duration get crossfadeDuration => _crossfadeDuration;

  set crossfadeDuration(Duration value) {
    if (value > _maxDuration) {
      _crossfadeDuration = _maxDuration;
    } else if (value < Duration.zero) {
      _crossfadeDuration = Duration.zero;
    } else {
      _crossfadeDuration = value;
    }
  }

  /// Whether crossfade is enabled (duration > 0).
  bool get isEnabled => _crossfadeDuration > Duration.zero;

  /// Whether a crossfade transition should start now.
  ///
  /// Returns true when the remaining playback time is within the
  /// crossfade window AND the track is long enough (>= 2x crossfade).
  bool shouldStartCrossfade({
    required Duration position,
    required Duration duration,
  }) {
    if (!isEnabled) return false;
    if (duration < _crossfadeDuration * 2) return false;

    final remaining = duration - position;
    return remaining <= _crossfadeDuration;
  }

  /// Calculate volume levels for crossfade at current position.
  ///
  /// Returns a record with `currentVolume` (fading out) and
  /// `nextVolume` (fading in), both in range 0.0 to 1.0.
  ({double currentVolume, double nextVolume}) calculateVolumes({
    required Duration position,
    required Duration duration,
  }) {
    if (!isEnabled) {
      return (currentVolume: 1.0, nextVolume: 0.0);
    }

    final remaining = duration - position;
    if (remaining >= _crossfadeDuration) {
      return (currentVolume: 1.0, nextVolume: 0.0);
    }

    // Linear fade: progress 0.0 (just started fading) → 1.0 (fully faded)
    final progress =
        1.0 - (remaining.inMilliseconds / _crossfadeDuration.inMilliseconds);
    final clamped = progress.clamp(0.0, 1.0);

    return (
      currentVolume: 1.0 - clamped,
      nextVolume: clamped,
    );
  }

  /// Cancel any active crossfade transition.
  void cancel() {
    // No-op for now; will be used when active crossfade tracking is added.
  }
}
