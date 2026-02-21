/// Sleep timer modes.
enum SleepTimerMode {
  /// Count down a fixed duration.
  timed,

  /// Stop after the current track ends.
  endOfTrack,

  /// Stop after N tracks complete.
  endOfNTracks,
}

/// Sleep timer that pauses playback after a set duration,
/// after the current track, or after N tracks.
class SleepTimerService {
  SleepTimerMode _mode = SleepTimerMode.timed;
  Duration _remaining = Duration.zero;
  int _remainingTracks = 0;
  bool _active = false;
  bool _paused = false;

  /// Called when the timer expires.
  void Function()? onTimerExpired;

  // ── Public getters ──

  bool get isActive => _active;
  Duration get remainingDuration => _remaining;
  SleepTimerMode get mode => _mode;
  int get remainingTracks => _remainingTracks;

  // ── Timer controls ──

  /// Start a countdown timer for the given duration.
  void startTimer(Duration duration) {
    _cancel();
    _mode = SleepTimerMode.timed;
    _remaining = duration;
    _active = true;
    _paused = false;
  }

  /// Stop after the current track ends.
  void startEndOfTrack() {
    _cancel();
    _mode = SleepTimerMode.endOfTrack;
    _remaining = Duration.zero;
    _active = true;
    _paused = false;
  }

  /// Stop after N tracks complete.
  void startEndOfNTracks(int n) {
    _cancel();
    _mode = SleepTimerMode.endOfNTracks;
    _remainingTracks = n;
    _remaining = Duration.zero;
    _active = true;
    _paused = false;
  }

  /// Cancel the active timer.
  void cancel() {
    _cancel();
  }

  // ── Event handlers ──

  /// Called every second to decrement the timed countdown.
  void tick() {
    if (!_active || _paused) return;
    if (_mode != SleepTimerMode.timed) return;

    _remaining -= const Duration(seconds: 1);
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _expire();
    }
  }

  /// Notify the timer that a track completed.
  void onTrackCompleted() {
    if (!_active) return;

    if (_mode == SleepTimerMode.endOfTrack) {
      _expire();
    } else if (_mode == SleepTimerMode.endOfNTracks) {
      _remainingTracks--;
      if (_remainingTracks <= 0) {
        _remainingTracks = 0;
        _expire();
      }
    }
  }

  /// Notify the timer that play state changed.
  /// Timer pauses when playback pauses.
  void onPlayStateChanged(bool isPlaying) {
    _paused = !isPlaying;
  }

  // ── Private ──

  void _cancel() {
    _active = false;
    _remaining = Duration.zero;
    _remainingTracks = 0;
  }

  void _expire() {
    _active = false;
    onTimerExpired?.call();
  }
}
