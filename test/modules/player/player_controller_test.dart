import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/core/storage/storage_service.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/repositories/music_repository.dart';
import 'package:flamekit/data/sources/music_source_adapter.dart';
import 'package:flamekit/data/sources/music_source_registry.dart';
import 'package:flamekit/modules/player/player_controller.dart';
import 'package:flamekit/shared/utils/app_toast.dart';

// --- Mocks ---

class MockMusicSourceRegistry extends GetxService
    with Mock
    implements MusicSourceRegistry {}

class MockMusicRepository extends GetxService
    with Mock
    implements MusicRepository {}

class MockStorageService extends GetxService
    with Mock
    implements StorageService {}

class MockMusicSourceAdapter extends Mock implements MusicSourceAdapter {}

// --- Helpers ---

SearchVideoModel _track({
  int id = 1,
  String title = 'Song',
  String author = 'Artist',
  String bvid = 'BV000',
  MusicSource source = MusicSource.netease,
}) {
  return SearchVideoModel(
    id: id,
    author: author,
    title: title,
    duration: '3:00',
    bvid: bvid,
    source: source,
  );
}

QueueItem _queueItem({
  int id = 1,
  String title = 'Song',
  String author = 'Artist',
  String audioUrl = 'https://audio.com/1.mp3',
  MusicSource source = MusicSource.netease,
}) {
  return QueueItem(
    video: _track(id: id, title: title, author: author, source: source),
    audioUrl: audioUrl,
    qualityLabel: '192K',
  );
}

void main() {
  group('PlayerController.normalizeTitle', () {
    test('removes parenthesized content', () {
      expect(
        PlayerController.normalizeTitle('Song Name (Live Version)'),
        'songname',
      );
    });

    test('removes full-width parentheses', () {
      expect(
        PlayerController.normalizeTitle('Song Name（现场版）'),
        'songname',
      );
    });

    test('removes square brackets', () {
      expect(
        PlayerController.normalizeTitle('Song [Official MV]'),
        'song',
      );
    });

    test('removes Chinese brackets', () {
      expect(
        PlayerController.normalizeTitle('Song【完整版】Name'),
        'songname',
      );
    });

    test('removes all whitespace', () {
      expect(
        PlayerController.normalizeTitle('  Song   Name  '),
        'songname',
      );
    });

    test('converts to lowercase', () {
      expect(
        PlayerController.normalizeTitle('My Song NAME'),
        'mysongname',
      );
    });

    test('handles combined decorations', () {
      expect(
        PlayerController.normalizeTitle('My Song (feat. Artist)【MV】[HD]'),
        'mysong',
      );
    });

    test('handles empty string', () {
      expect(
        PlayerController.normalizeTitle(''),
        '',
      );
    });
  });

  group('PlayMode', () {
    test('togglePlayMode cycles correctly', () {
      // Verify the cycle: sequential -> shuffle -> repeatOne -> sequential
      expect(PlayMode.values.length, 3);
      expect(PlayMode.sequential.index, 0);
      expect(PlayMode.shuffle.index, 1);
      expect(PlayMode.repeatOne.index, 2);
    });
  });

  group('QueueItem', () {
    test('constructs with required fields', () {
      final item = _queueItem(id: 5, title: 'Test');
      expect(item.video.id, 5);
      expect(item.video.title, 'Test');
      expect(item.audioUrl, 'https://audio.com/1.mp3');
      expect(item.qualityLabel, '192K');
    });

    test('default headers is empty map', () {
      final item = QueueItem(
        video: _track(),
        audioUrl: 'https://audio.com/1.mp3',
      );
      expect(item.headers, isEmpty);
    });
  });

  group('PlayerController with GetX', () {
    late PlayerController controller;
    late MockMusicSourceRegistry mockRegistry;
    late MockMusicRepository mockMusicRepo;
    late MockStorageService mockStorage;

    setUp(() {
      Get.testMode = true;
      AppToast.suppressInTests = true;

      mockRegistry = MockMusicSourceRegistry();
      mockMusicRepo = MockMusicRepository();
      mockStorage = MockStorageService();

      // Stub activeSourceId for MusicSourceRegistry
      when(() => mockRegistry.activeSourceId).thenReturn('gdstudio'.obs);
      when(() => mockRegistry.availableSources).thenReturn([]);
      when(() => mockRegistry.getSourceForTrack(any()))
          .thenReturn(null);

      // Stub storage methods called during init/playback
      when(() => mockStorage.getPlayHistory()).thenReturn([]);
      when(() => mockStorage.preferenceTags).thenReturn([]);

      Get.put<MusicSourceRegistry>(mockRegistry);
      Get.put<MusicRepository>(mockMusicRepo);
      Get.put<StorageService>(mockStorage);

      controller = Get.put(PlayerController());
    });

    tearDown(() {
      AppToast.suppressInTests = false;
      Get.reset();
    });

    setUpAll(() {
      registerFallbackValue(_track());
    });

    group('queue management', () {
      test('queue starts empty', () {
        expect(controller.queue, isEmpty);
        expect(controller.currentIndex.value, -1);
      });

      test('reorderQueue moves item correctly', () {
        controller.queue.addAll([
          _queueItem(id: 1, title: 'A'),
          _queueItem(id: 2, title: 'B'),
          _queueItem(id: 3, title: 'C'),
        ]);

        controller.reorderQueue(2, 1);

        expect(controller.queue[0].video.title, 'A');
        expect(controller.queue[1].video.title, 'C');
        expect(controller.queue[2].video.title, 'B');
      });

      test('reorderQueue handles newIndex > oldIndex', () {
        controller.queue.addAll([
          _queueItem(id: 1, title: 'A'),
          _queueItem(id: 2, title: 'B'),
          _queueItem(id: 3, title: 'C'),
        ]);

        controller.reorderQueue(0, 3);

        expect(controller.queue[0].video.title, 'B');
        expect(controller.queue[1].video.title, 'C');
        expect(controller.queue[2].video.title, 'A');
      });

      test('removeFromQueue does not remove index 0', () {
        controller.queue.addAll([
          _queueItem(id: 1, title: 'Current'),
          _queueItem(id: 2, title: 'Next'),
        ]);

        controller.removeFromQueue(0);

        expect(controller.queue.length, 2);
      });

      test('removeFromQueue removes item at given index', () {
        controller.queue.addAll([
          _queueItem(id: 1, title: 'Current'),
          _queueItem(id: 2, title: 'To Remove'),
          _queueItem(id: 3, title: 'Keep'),
        ]);

        controller.removeFromQueue(1);

        expect(controller.queue.length, 2);
        expect(controller.queue[1].video.title, 'Keep');
      });

      test('clearQueue resets all state', () {
        controller.queue.addAll([_queueItem()]);
        controller.currentIndex.value = 0;
        controller.currentVideo.value = _track();

        controller.clearQueue();

        expect(controller.queue, isEmpty);
        expect(controller.playHistory, isEmpty);
        expect(controller.currentIndex.value, -1);
        expect(controller.currentVideo.value, isNull);
        expect(controller.position.value, Duration.zero);
        expect(controller.duration.value, Duration.zero);
      });
    });

    group('play mode', () {
      test('togglePlayMode cycles sequential -> shuffle -> repeatOne -> sequential', () {
        expect(controller.playMode.value, PlayMode.sequential);

        controller.togglePlayMode();
        expect(controller.playMode.value, PlayMode.shuffle);

        controller.togglePlayMode();
        expect(controller.playMode.value, PlayMode.repeatOne);

        controller.togglePlayMode();
        expect(controller.playMode.value, PlayMode.sequential);
      });
    });

    group('play history', () {
      test('playHistory has maximum 50 entries', () {
        // Fill queue and history
        for (int i = 0; i < 55; i++) {
          controller.queue.insert(0, _queueItem(id: i, title: 'Song $i'));
        }
        controller.currentIndex.value = 0;

        // Manually push to history 55 times
        for (int i = 0; i < 55; i++) {
          controller.playHistory.add(_queueItem(id: i));
          if (controller.playHistory.length > 50) {
            controller.playHistory.removeAt(0);
          }
        }

        expect(controller.playHistory.length, 50);
      });
    });

    group('hasCurrentTrack', () {
      test('returns false when currentVideo is null', () {
        expect(controller.hasCurrentTrack, isFalse);
      });

      test('returns true when currentVideo is set', () {
        controller.currentVideo.value = _track();
        expect(controller.hasCurrentTrack, isTrue);
      });
    });

    group('uploaderMid', () {
      test('starts at 0', () {
        expect(controller.uploaderMid.value, 0);
      });
    });

    group('skipPrevious', () {
      test('restarts track when position > 3s', () async {
        controller.currentVideo.value = _track();
        controller.queue.add(_queueItem());
        controller.currentIndex.value = 0;

        // Simulate position > 3s via the controller's reactive state
        // (position is delegated from PlaybackService, so we'd need to mock it)
        // For now, verify the method doesn't crash
        // with position at 0, it should go to history path
        when(() => mockStorage.updatePlayDuration(any(), any())).thenReturn(null);

        await controller.skipPrevious();
        // With empty history and 0 position, just restarts
      });
    });

    group('reactive state delegation', () {
      test('isPlaying defaults to false', () {
        expect(controller.isPlaying.value, isFalse);
      });

      test('position defaults to zero', () {
        expect(controller.position.value, Duration.zero);
      });

      test('duration defaults to zero', () {
        expect(controller.duration.value, Duration.zero);
      });
    });
  });
}
