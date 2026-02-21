import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/player/audio_stream_model.dart';

void main() {
  group('AudioQualityId', () {
    test('priority returns correct ordering', () {
      expect(AudioQualityId.priority(AudioQualityId.hiRes), 5);
      expect(AudioQualityId.priority(AudioQualityId.dolby), 4);
      expect(AudioQualityId.priority(AudioQualityId.k192), 3);
      expect(AudioQualityId.priority(AudioQualityId.k132), 2);
      expect(AudioQualityId.priority(AudioQualityId.k64), 1);
    });

    test('priority returns 0 for unknown id', () {
      expect(AudioQualityId.priority(99999), 0);
    });

    test('label returns correct labels', () {
      expect(AudioQualityId.label(AudioQualityId.hiRes), 'Hi-Res');
      expect(AudioQualityId.label(AudioQualityId.dolby), 'Dolby');
      expect(AudioQualityId.label(AudioQualityId.k192), '192K');
      expect(AudioQualityId.label(AudioQualityId.k132), '132K');
      expect(AudioQualityId.label(AudioQualityId.k64), '64K');
    });

    test('label returns id as string for unknown id', () {
      expect(AudioQualityId.label(12345), '12345');
    });

    test('priority ordering is strictly increasing with quality', () {
      final ids = [
        AudioQualityId.k64,
        AudioQualityId.k132,
        AudioQualityId.k192,
        AudioQualityId.dolby,
        AudioQualityId.hiRes,
      ];

      for (int i = 0; i < ids.length - 1; i++) {
        expect(
          AudioQualityId.priority(ids[i]),
          lessThan(AudioQualityId.priority(ids[i + 1])),
          reason: '${ids[i]} should have lower priority than ${ids[i + 1]}',
        );
      }
    });
  });

  group('AudioStreamModel.fromJson', () {
    test('parses camelCase fields (Bilibili API style)', () {
      final json = {
        'id': AudioQualityId.k192,
        'baseUrl': 'https://audio.bilibili.com/stream.m4a',
        'backupUrl': ['https://backup.bilibili.com/stream.m4a'],
        'bandWidth': 192000,
        'mimeType': 'audio/mp4',
        'codecs': 'mp4a.40.2',
        'codecid': 0,
      };

      final model = AudioStreamModel.fromJson(json);

      expect(model.id, AudioQualityId.k192);
      expect(model.baseUrl, 'https://audio.bilibili.com/stream.m4a');
      expect(model.backupUrl, 'https://backup.bilibili.com/stream.m4a');
      expect(model.bandwidth, 192000);
      expect(model.mimeType, 'audio/mp4');
      expect(model.codecs, 'mp4a.40.2');
    });

    test('parses snake_case fields', () {
      final json = {
        'id': AudioQualityId.k64,
        'base_url': 'https://cdn.example.com/audio.m4a',
        'backup_url': ['https://cdn-backup.example.com/audio.m4a'],
        'bandwidth': 64000,
        'mime_type': 'audio/mp4',
        'codecs': 'mp4a.40.2',
        'codecid': 1,
      };

      final model = AudioStreamModel.fromJson(json);

      expect(model.baseUrl, 'https://cdn.example.com/audio.m4a');
      expect(model.backupUrl, 'https://cdn-backup.example.com/audio.m4a');
      expect(model.bandwidth, 64000);
      expect(model.mimeType, 'audio/mp4');
    });

    test('handles missing backupUrl', () {
      final json = {
        'id': AudioQualityId.k132,
        'baseUrl': 'https://audio.com/stream.m4a',
        'bandWidth': 132000,
        'codecs': 'mp4a.40.2',
        'codecid': 0,
      };

      final model = AudioStreamModel.fromJson(json);

      expect(model.backupUrl, isNull);
    });

    test('handles empty backupUrl list', () {
      final json = {
        'id': AudioQualityId.k132,
        'baseUrl': 'https://audio.com/stream.m4a',
        'backupUrl': <String>[],
        'bandWidth': 132000,
        'codecs': '',
        'codecid': 0,
      };

      final model = AudioStreamModel.fromJson(json);

      expect(model.backupUrl, isNull);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = AudioStreamModel.fromJson(json);

      expect(model.id, 0);
      expect(model.baseUrl, '');
      expect(model.backupUrl, isNull);
      expect(model.bandwidth, 0);
      expect(model.mimeType, '');
      expect(model.codecs, '');
      expect(model.codecid, 0);
    });
  });

  group('AudioStreamModel getters', () {
    test('qualityLabel delegates to AudioQualityId.label', () {
      final model = AudioStreamModel(
        id: AudioQualityId.hiRes,
        baseUrl: '',
        bandwidth: 0,
        mimeType: '',
        codecs: '',
        codecid: 0,
      );

      expect(model.qualityLabel, 'Hi-Res');
    });

    test('qualityPriority delegates to AudioQualityId.priority', () {
      final model = AudioStreamModel(
        id: AudioQualityId.dolby,
        baseUrl: '',
        bandwidth: 0,
        mimeType: '',
        codecs: '',
        codecid: 0,
      );

      expect(model.qualityPriority, 4);
    });

    test('isPremium returns true for Dolby', () {
      final model = AudioStreamModel(
        id: AudioQualityId.dolby,
        baseUrl: '',
        bandwidth: 0,
        mimeType: '',
        codecs: '',
        codecid: 0,
      );

      expect(model.isPremium, isTrue);
    });

    test('isPremium returns true for Hi-Res', () {
      final model = AudioStreamModel(
        id: AudioQualityId.hiRes,
        baseUrl: '',
        bandwidth: 0,
        mimeType: '',
        codecs: '',
        codecid: 0,
      );

      expect(model.isPremium, isTrue);
    });

    test('isPremium returns false for standard quality', () {
      final model = AudioStreamModel(
        id: AudioQualityId.k192,
        baseUrl: '',
        bandwidth: 0,
        mimeType: '',
        codecs: '',
        codecid: 0,
      );

      expect(model.isPremium, isFalse);
    });
  });
}
