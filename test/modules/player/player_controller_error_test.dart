import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/core/storage/storage_service.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/repositories/music_repository.dart';
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

// --- Helpers ---

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

QueueItem _queueItem({
  int id = 1,
  String title = 'Song',
  MusicSource source = MusicSource.netease,
}) {
  return QueueItem(
    video: _track(id: id, title: title, source: source),
    audioUrl: 'https://audio.com/$id.mp3',
  );
}

void main() {
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

    when(() => mockRegistry.activeSourceId).thenReturn('gdstudio'.obs);
    when(() => mockRegistry.availableSources).thenReturn([]);
    when(() => mockRegistry.getSourceForTrack(any())).thenReturn(null);

    when(() => mockStorage.getPlayHistory()).thenReturn([]);
    when(() => mockStorage.preferenceTags).thenReturn([]);
    when(() => mockStorage.updatePlayDuration(any(), any())).thenReturn(null);

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

  group('error resilience', () {
    test('clearQueue does not crash on empty state', () {
      // No items in queue
      controller.clearQueue();

      expect(controller.queue, isEmpty);
      expect(controller.currentIndex.value, -1);
    });

    test('removeFromQueue does not crash on out-of-bounds index', () {
      controller.queue.add(_queueItem());

      // Try removing at invalid index — should not throw
      controller.removeFromQueue(99);

      expect(controller.queue.length, 1);
    });

    test('reorderQueue handles same old and new index', () {
      controller.queue.addAll([
        _queueItem(id: 1, title: 'A'),
        _queueItem(id: 2, title: 'B'),
      ]);

      // Same position — no change
      controller.reorderQueue(0, 0);

      expect(controller.queue[0].video.title, 'A');
      expect(controller.queue[1].video.title, 'B');
    });

    test('togglePlayMode does not crash when called rapidly', () {
      // Rapid cycling should be safe
      for (int i = 0; i < 100; i++) {
        controller.togglePlayMode();
      }

      // 100 % 3 = 1 → shuffle (starting from sequential at index 0)
      expect(controller.playMode.value, PlayMode.shuffle);
    });

    test('currentVideo stays null when queue is empty and skipNext is called', () async {
      // Empty queue
      await controller.skipNext();

      expect(controller.currentVideo.value, isNull);
    });

    test('skipPrevious with empty history and empty queue does not crash', () async {
      await controller.skipPrevious();

      expect(controller.currentVideo.value, isNull);
    });
  });
}
