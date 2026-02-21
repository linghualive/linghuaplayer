/// Manages playback speed settings.
///
/// Supports standard speed values from 0.5x to 2.0x.
/// Speed persists across track changes within a session.
class PlaybackSpeedService {
  static const supportedSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  double _speed = 1.0;

  /// Current playback speed multiplier.
  double get speed => _speed;

  /// Human-readable speed label (e.g., "1.5x").
  String get speedLabel => '${_speed}x';

  /// Set playback speed. Ignores unsupported values.
  void setSpeed(double value) {
    if (supportedSpeeds.contains(value)) {
      _speed = value;
    }
  }

  /// Cycle to the next speed in the supported list.
  void cycleSpeed() {
    final index = supportedSpeeds.indexOf(_speed);
    final nextIndex = (index + 1) % supportedSpeeds.length;
    _speed = supportedSpeeds[nextIndex];
  }
}
