/// Per-source volume normalization.
///
/// Since source APIs don't provide loudness metadata, this uses
/// fixed per-source gain adjustments based on observed loudness
/// characteristics. Unknown sources get neutral (1.0) gain.
class VolumeNormalizationService {
  /// Minimum gain multiplier (~-20dB).
  static const minGain = 0.1;

  /// Maximum gain multiplier (~+6dB).
  static const maxGain = 2.0;

  /// Per-source gain adjustments.
  /// Values determined empirically based on typical loudness levels.
  static const _sourceGains = {
    'bilibili': 0.85, // Bilibili tends to be louder
    'netease': 1.0, // Netease as reference level
    'qqmusic': 0.95, // QQ Music slightly louder
    'gdstudio': 1.1, // GDStudio tends to be quieter
  };

  bool _enabled = false;

  /// Whether volume normalization is active.
  bool get isEnabled => _enabled;

  set isEnabled(bool value) => _enabled = value;

  /// Get the gain multiplier for a given source.
  ///
  /// Returns 1.0 (neutral) when disabled or for unknown sources.
  double getGainForSource(String sourceId) {
    if (!_enabled) return 1.0;

    final gain = _sourceGains[sourceId] ?? 1.0;
    return gain.clamp(minGain, maxGain);
  }
}
