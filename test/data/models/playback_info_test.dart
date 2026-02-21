import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/playback_info.dart';

void main() {
  group('PlaybackInfo.bestAudio', () {
    test('returns first stream when list is not empty', () {
      final info = PlaybackInfo(
        audioStreams: [
          const StreamOption(url: 'https://stream1.mp3', qualityLabel: 'HQ'),
          const StreamOption(url: 'https://stream2.mp3', qualityLabel: 'LQ'),
        ],
        sourceId: 'test',
      );

      final best = info.bestAudio;

      expect(best, isNotNull);
      expect(best!.url, 'https://stream1.mp3');
      expect(best.qualityLabel, 'HQ');
    });

    test('returns null when audioStreams is empty', () {
      const info = PlaybackInfo(
        audioStreams: [],
        sourceId: 'test',
      );

      expect(info.bestAudio, isNull);
    });
  });

  group('StreamOption', () {
    test('constructs with all fields', () {
      const stream = StreamOption(
        url: 'https://audio.mp3',
        backupUrl: 'https://backup.mp3',
        qualityLabel: '320K',
        bandwidth: 320000,
        codec: 'mp3',
        headers: {'Referer': 'https://example.com'},
      );

      expect(stream.url, 'https://audio.mp3');
      expect(stream.backupUrl, 'https://backup.mp3');
      expect(stream.qualityLabel, '320K');
      expect(stream.bandwidth, 320000);
      expect(stream.codec, 'mp3');
      expect(stream.headers, {'Referer': 'https://example.com'});
    });

    test('has sensible defaults for optional fields', () {
      const stream = StreamOption(url: 'https://audio.mp3');

      expect(stream.backupUrl, isNull);
      expect(stream.qualityLabel, '');
      expect(stream.bandwidth, 0);
      expect(stream.codec, '');
      expect(stream.headers, isEmpty);
    });
  });
}
