import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/modules/player/player_controller.dart';

SearchVideoModel _track({
  int id = 1,
  String title = 'Song',
  String author = 'Artist',
  MusicSource source = MusicSource.netease,
}) {
  return SearchVideoModel(
    id: id,
    author: author,
    title: title,
    duration: '3:00',
    source: source,
  );
}

void main() {
  group('QueueItem serialization', () {
    test('toJson produces correct map', () {
      final item = QueueItem(
        video: _track(id: 42, title: 'My Song', author: 'My Artist'),
        audioUrl: 'https://audio.com/42.mp3',
        qualityLabel: '192K',
        headers: {'Referer': 'https://example.com'},
      );

      final json = item.toJson();

      expect(json['audioUrl'], 'https://audio.com/42.mp3');
      expect(json['qualityLabel'], '192K');
      expect(json['headers'], {'Referer': 'https://example.com'});
      expect(json['video'], isA<Map<String, dynamic>>());
      expect(json['video']['title'], 'My Song');
    });

    test('fromJson restores correct item', () {
      final json = {
        'video': {
          'id': 99,
          'author': 'Artist',
          'title': 'Restored Song',
          'duration': '4:00',
          'source': 'qqmusic',
        },
        'audioUrl': 'https://audio.com/99.mp3',
        'qualityLabel': '320K',
        'headers': {'Cookie': 'abc=123'},
      };

      final item = QueueItem.fromJson(json);

      expect(item.video.id, 99);
      expect(item.video.title, 'Restored Song');
      expect(item.video.source, MusicSource.qqmusic);
      expect(item.audioUrl, 'https://audio.com/99.mp3');
      expect(item.qualityLabel, '320K');
      expect(item.headers, {'Cookie': 'abc=123'});
    });

    test('toJson/fromJson roundtrip preserves all fields', () {
      final original = QueueItem(
        video: _track(
          id: 7,
          title: 'Round Trip',
          author: 'Tester',
          source: MusicSource.gdstudio,
        ),
        audioUrl: 'https://cdn.com/7.m4a',
        qualityLabel: 'Hi-Res',
        headers: {'User-Agent': 'FlameKit'},
      );

      final restored = QueueItem.fromJson(original.toJson());

      expect(restored.video.id, original.video.id);
      expect(restored.video.title, original.video.title);
      expect(restored.video.author, original.video.author);
      expect(restored.video.source, original.video.source);
      expect(restored.audioUrl, original.audioUrl);
      expect(restored.qualityLabel, original.qualityLabel);
      expect(restored.headers, original.headers);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = <String, dynamic>{
        'video': {'id': 1, 'title': 'Minimal'},
      };

      final item = QueueItem.fromJson(json);

      expect(item.video.id, 1);
      expect(item.audioUrl, '');
      expect(item.qualityLabel, '');
      expect(item.headers, isEmpty);
    });

    test('fromJson handles completely empty JSON', () {
      final item = QueueItem.fromJson({});

      expect(item.audioUrl, '');
      expect(item.qualityLabel, '');
      expect(item.headers, isEmpty);
    });

    test('serialization works for all MusicSource types', () {
      for (final source in MusicSource.values) {
        final item = QueueItem(
          video: _track(source: source, id: source.index),
          audioUrl: 'https://audio.com/${source.name}.mp3',
        );

        final restored = QueueItem.fromJson(item.toJson());
        expect(restored.video.source, source);
      }
    });
  });
}
