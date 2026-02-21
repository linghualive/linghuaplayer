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

void main() {
  late PlayerController controller;
  late MockMusicSourceRegistry mockRegistry;

  setUp(() {
    Get.testMode = true;
    AppToast.suppressInTests = true;

    mockRegistry = MockMusicSourceRegistry();
    final mockMusicRepo = MockMusicRepository();
    final mockStorage = MockStorageService();

    when(() => mockRegistry.activeSourceId).thenReturn('gdstudio'.obs);
    when(() => mockRegistry.availableSources).thenReturn([]);
    when(() => mockRegistry.getSourceForTrack(any())).thenReturn(null);

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
    registerFallbackValue(SearchVideoModel(
      id: 0, author: '', title: '', duration: '',
      source: MusicSource.bilibili,
    ));
  });

  group('MiniPlayerBar logic', () {
    test('should be hidden when no current track', () {
      expect(controller.hasCurrentTrack, isFalse);
      expect(controller.currentVideo.value, isNull);
    });

    test('should be visible when track is playing', () {
      controller.currentVideo.value = SearchVideoModel(
        id: 1,
        author: 'Artist',
        title: 'Song Title',
        duration: '3:00',
        source: MusicSource.netease,
      );

      expect(controller.hasCurrentTrack, isTrue);
      expect(controller.currentVideo.value!.title, 'Song Title');
      expect(controller.currentVideo.value!.author, 'Artist');
    });

    test('play/pause state is reactive', () {
      expect(controller.isPlaying.value, isFalse);
    });

    test('progress is available', () {
      expect(controller.position.value, Duration.zero);
      expect(controller.duration.value, Duration.zero);
    });

    test('track info updates when track changes', () {
      controller.currentVideo.value = SearchVideoModel(
        id: 1, author: 'A', title: 'First', duration: '2:00',
        source: MusicSource.netease,
      );
      expect(controller.currentVideo.value!.title, 'First');

      controller.currentVideo.value = SearchVideoModel(
        id: 2, author: 'B', title: 'Second', duration: '3:00',
        source: MusicSource.netease,
      );
      expect(controller.currentVideo.value!.title, 'Second');
    });
  });
}
