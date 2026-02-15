class LyricsLine {
  final Duration timestamp;
  final String text;

  const LyricsLine({required this.timestamp, required this.text});
}

class LyricsData {
  final List<LyricsLine> lines;
  final String? plainLyrics;

  const LyricsData({required this.lines, this.plainLyrics});

  bool get hasSyncedLyrics => lines.isNotEmpty;

  /// Parse standard LRC format: [mm:ss.xx]text
  static LyricsData? fromLrc(String lrc) {
    final lines = <LyricsLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = match.group(3)!;
        final millis = centiseconds.length == 2
            ? int.parse(centiseconds) * 10
            : int.parse(centiseconds);
        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          lines.add(LyricsLine(
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: millis,
            ),
            text: text,
          ));
        }
      }
    }

    if (lines.isEmpty) return null;
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return LyricsData(lines: lines);
  }

  /// Parse Bilibili subtitle JSON: [{from, to, content}, ...]
  static LyricsData? fromBilibiliSubtitle(List<dynamic> body) {
    final lines = <LyricsLine>[];

    for (final item in body) {
      final from = item['from'];
      final content = item['content'] as String? ?? '';
      if (from == null || content.isEmpty) continue;

      final seconds = (from as num).toDouble();
      final millis = (seconds * 1000).round();

      lines.add(LyricsLine(
        timestamp: Duration(milliseconds: millis),
        text: content,
      ));
    }

    if (lines.isEmpty) return null;
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return LyricsData(lines: lines);
  }
}
