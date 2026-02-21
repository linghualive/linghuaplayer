import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/modules/player/player_controller.dart';
import 'package:flamekit/modules/player/services/queue_persistence_service.dart';

QueueItem _queueItem({int id = 1, String title = 'Song'}) {
  return QueueItem(
    video: SearchVideoModel(
      id: id,
      author: 'Artist',
      title: title,
      duration: '3:00',
      source: MusicSource.netease,
    ),
    audioUrl: 'https://audio.com/$id.mp3',
    qualityLabel: '192K',
  );
}

void main() {
  group('QueuePersistenceService', () {
    late QueuePersistenceService service;
    final storage = <String, String>{};

    setUp(() {
      storage.clear();
      service = QueuePersistenceService(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value,
        remove: (key) => storage.remove(key),
      );
    });

    test('saveQueue writes serialized data', () {
      final queue = [_queueItem(id: 1), _queueItem(id: 2)];

      service.saveQueue(
        queue: queue,
        currentIndex: 0,
        position: const Duration(seconds: 30),
        playMode: PlayMode.shuffle,
      );

      expect(storage.containsKey('saved_queue'), isTrue);
      final data = jsonDecode(storage['saved_queue']!);
      expect(data['items'].length, 2);
      expect(data['currentIndex'], 0);
      expect(data['positionMs'], 30000);
      expect(data['playMode'], 'shuffle');
    });

    test('restoreQueue returns saved state', () {
      final queue = [_queueItem(id: 1, title: 'A'), _queueItem(id: 2, title: 'B')];
      service.saveQueue(
        queue: queue,
        currentIndex: 1,
        position: const Duration(seconds: 45),
        playMode: PlayMode.repeatOne,
      );

      final result = service.restoreQueue();

      expect(result, isNotNull);
      expect(result!.items.length, 2);
      expect(result.items[0].video.title, 'A');
      expect(result.items[1].video.title, 'B');
      expect(result.currentIndex, 1);
      expect(result.position.inSeconds, 45);
      expect(result.playMode, PlayMode.repeatOne);
    });

    test('restoreQueue returns null when nothing saved', () {
      final result = service.restoreQueue();

      expect(result, isNull);
    });

    test('corrupted data returns null', () {
      storage['saved_queue'] = 'not json at all {{{';

      final result = service.restoreQueue();

      expect(result, isNull);
    });

    test('missing items key returns null', () {
      storage['saved_queue'] = jsonEncode({'currentIndex': 0});

      final result = service.restoreQueue();

      expect(result, isNull);
    });

    test('saves and restores position within 2s precision', () {
      service.saveQueue(
        queue: [_queueItem()],
        currentIndex: 0,
        position: const Duration(seconds: 127, milliseconds: 456),
        playMode: PlayMode.sequential,
      );

      final result = service.restoreQueue();

      expect(result, isNotNull);
      final diff = (result!.position - const Duration(seconds: 127, milliseconds: 456)).abs();
      expect(diff.inSeconds, lessThanOrEqualTo(2));
    });

    test('saves and restores play mode', () {
      for (final mode in PlayMode.values) {
        service.saveQueue(
          queue: [_queueItem()],
          currentIndex: 0,
          position: Duration.zero,
          playMode: mode,
        );

        final result = service.restoreQueue();
        expect(result!.playMode, mode);
      }
    });

    test('limits serialized items to 100', () {
      final queue = List.generate(150, (i) => _queueItem(id: i));

      service.saveQueue(
        queue: queue,
        currentIndex: 0,
        position: Duration.zero,
        playMode: PlayMode.sequential,
      );

      final result = service.restoreQueue();
      expect(result!.items.length, 100);
    });

    test('clear removes saved data', () {
      service.saveQueue(
        queue: [_queueItem()],
        currentIndex: 0,
        position: Duration.zero,
        playMode: PlayMode.sequential,
      );

      service.clear();

      expect(service.restoreQueue(), isNull);
    });
  });
}
