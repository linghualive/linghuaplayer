class DurationFormatter {
  /// Format duration string like "4:30" or seconds to "MM:SS"
  static String format(dynamic duration) {
    if (duration is String) {
      return duration;
    }
    if (duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    if (duration is Duration) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '00:00';
  }
}
