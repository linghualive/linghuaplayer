import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/player/lyrics_model.dart';

void main() {
  group('LyricsData.fromLrc', () {
    test('parses standard [mm:ss.cc] format', () {
      const lrc = '''[00:01.50]First line
[00:05.00]Second line
[00:10.99]Third line''';

      final result = LyricsData.fromLrc(lrc);

      expect(result, isNotNull);
      expect(result!.lines.length, 3);
      expect(result.lines[0].text, 'First line');
      expect(result.lines[0].timestamp, const Duration(seconds: 1, milliseconds: 500));
      expect(result.lines[1].text, 'Second line');
      expect(result.lines[1].timestamp, const Duration(seconds: 5));
      expect(result.lines[2].text, 'Third line');
      expect(result.lines[2].timestamp, const Duration(seconds: 10, milliseconds: 990));
    });

    test('parses 3-digit millisecond format [mm:ss.ccc]', () {
      const lrc = '[01:30.456]Line with 3-digit ms';

      final result = LyricsData.fromLrc(lrc);

      expect(result, isNotNull);
      expect(result!.lines.length, 1);
      expect(result.lines[0].timestamp,
          const Duration(minutes: 1, seconds: 30, milliseconds: 456));
      expect(result.lines[0].text, 'Line with 3-digit ms');
    });

    test('filters empty text lines', () {
      const lrc = '''[00:01.00]Real line
[00:02.00]
[00:03.00]
[00:04.00]Another real line''';

      final result = LyricsData.fromLrc(lrc);

      expect(result, isNotNull);
      expect(result!.lines.length, 2);
      expect(result.lines[0].text, 'Real line');
      expect(result.lines[1].text, 'Another real line');
    });

    test('ignores metadata tags like [ti:], [ar:]', () {
      const lrc = '''[ti:Song Title]
[ar:Artist Name]
[al:Album Name]
[00:01.00]First lyric line''';

      final result = LyricsData.fromLrc(lrc);

      expect(result, isNotNull);
      expect(result!.lines.length, 1);
      expect(result.lines[0].text, 'First lyric line');
    });

    test('sorts lines by timestamp', () {
      const lrc = '''[00:10.00]Third
[00:01.00]First
[00:05.00]Second''';

      final result = LyricsData.fromLrc(lrc);

      expect(result, isNotNull);
      expect(result!.lines[0].text, 'First');
      expect(result.lines[1].text, 'Second');
      expect(result.lines[2].text, 'Third');
    });

    test('returns null for empty input', () {
      expect(LyricsData.fromLrc(''), isNull);
    });

    test('returns null for input with no valid lines', () {
      const lrc = '''[ti:Song Title]
[ar:Artist Name]
some random text without timestamps''';

      expect(LyricsData.fromLrc(lrc), isNull);
    });

    test('handles 2-digit centisecond vs 3-digit millisecond correctly', () {
      const lrc2 = '[00:01.05]Two digit';
      const lrc3 = '[00:01.050]Three digit';

      final r2 = LyricsData.fromLrc(lrc2);
      final r3 = LyricsData.fromLrc(lrc3);

      // 05 centiseconds = 50 milliseconds
      expect(r2!.lines[0].timestamp, const Duration(seconds: 1, milliseconds: 50));
      // 050 milliseconds = 50 milliseconds
      expect(r3!.lines[0].timestamp, const Duration(seconds: 1, milliseconds: 50));
    });
  });

  group('LyricsData.fromBilibiliSubtitle', () {
    test('parses normal subtitle JSON', () {
      final body = [
        {'from': 1.5, 'to': 3.0, 'content': 'Hello'},
        {'from': 5.0, 'to': 7.0, 'content': 'World'},
      ];

      final result = LyricsData.fromBilibiliSubtitle(body);

      expect(result, isNotNull);
      expect(result!.lines.length, 2);
      expect(result.lines[0].text, 'Hello');
      expect(result.lines[0].timestamp, const Duration(milliseconds: 1500));
      expect(result.lines[1].text, 'World');
      expect(result.lines[1].timestamp, const Duration(milliseconds: 5000));
    });

    test('returns null for empty list', () {
      expect(LyricsData.fromBilibiliSubtitle([]), isNull);
    });

    test('skips entries with missing content or from field', () {
      final body = [
        {'from': 1.0, 'content': 'Valid'},
        {'from': 2.0, 'content': ''},
        {'to': 3.0, 'content': 'No from'},
        {'from': 4.0, 'content': 'Also valid'},
      ];

      final result = LyricsData.fromBilibiliSubtitle(body);

      expect(result, isNotNull);
      expect(result!.lines.length, 2);
      expect(result.lines[0].text, 'Valid');
      expect(result.lines[1].text, 'Also valid');
    });

    test('handles integer from values', () {
      final body = [
        {'from': 10, 'content': 'Integer seconds'},
      ];

      final result = LyricsData.fromBilibiliSubtitle(body);

      expect(result, isNotNull);
      expect(result!.lines[0].timestamp, const Duration(seconds: 10));
    });
  });

  group('LyricsData.hasSyncedLyrics', () {
    test('returns true when lines are not empty', () {
      final data = LyricsData(lines: [
        LyricsLine(timestamp: Duration.zero, text: 'test'),
      ]);
      expect(data.hasSyncedLyrics, isTrue);
    });

    test('returns false when lines are empty', () {
      const data = LyricsData(lines: []);
      expect(data.hasSyncedLyrics, isFalse);
    });
  });
}
