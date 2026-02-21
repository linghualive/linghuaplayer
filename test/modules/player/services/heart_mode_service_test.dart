import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/core/storage/storage_service.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/services/recommendation_service.dart';
import 'package:flamekit/modules/player/player_controller.dart';
import 'package:flamekit/modules/player/services/heart_mode_service.dart';
import 'package:flamekit/shared/utils/app_toast.dart';

// --- Mocks ---

class MockRecommendationService extends Mock implements RecommendationService {}

// StorageService extends GetxService, so we need to extend GetxService to
// get proper lifecycle callbacks, and mix in Mock for mocktail.
class MockStorageService extends GetxService with Mock implements StorageService {}

// --- Helpers ---

SearchVideoModel _track({int id = 1, String title = 'Song', String author = 'Artist'}) {
  return SearchVideoModel(
    id: id,
    author: author,
    title: title,
    duration: '3:00',
    source: MusicSource.netease,
  );
}

QueueItem _queueItem({int id = 1, String title = 'Song'}) {
  return QueueItem(
    video: _track(id: id, title: title),
    audioUrl: 'https://audio.com/$id.mp3',
  );
}

void main() {
  late HeartModeService heartMode;
  late MockRecommendationService mockRecService;
  late MockStorageService mockStorage;

  setUp(() {
    Get.testMode = true;
    AppToast.suppressInTests = true;

    heartMode = HeartModeService();
    mockRecService = MockRecommendationService();
    mockStorage = MockStorageService();

    Get.put<RecommendationService>(mockRecService);
    Get.put<StorageService>(mockStorage);
  });

  tearDown(() {
    AppToast.suppressInTests = false;
    Get.reset();
  });

  group('activate', () {
    test('saves current queue, gets recommendations, and plays first song', () async {
      final songs = [_track(id: 1, title: 'Rec1'), _track(id: 2, title: 'Rec2')];
      final savedQueue = [_queueItem(id: 10), _queueItem(id: 11)];
      final currentVideo = _track(id: 10);

      heartMode.getCurrentQueue = () => List.from(savedQueue);
      heartMode.getCurrentVideo = () => currentVideo;

      bool playFromSearchCalled = false;
      int addToQueueCount = 0;

      heartMode.onPlayFromSearch = (video) async {
        playFromSearchCalled = true;
        expect(video.uniqueId, songs.first.uniqueId);
      };
      heartMode.onAddToQueueSilent = (video) async {
        addToQueueCount++;
        return true;
      };

      when(() => mockRecService.getRecommendations(tags: ['pop', 'rock']))
          .thenAnswer((_) async => songs);

      await heartMode.activate(['pop', 'rock']);

      expect(heartMode.isHeartMode.value, isTrue);
      expect(heartMode.heartModeTags, ['pop', 'rock']);
      expect(heartMode.isHeartModeLoading.value, isFalse);
      expect(playFromSearchCalled, isTrue);
      expect(addToQueueCount, 1); // songs[1]
    });

    test('restores queue on empty recommendations', () async {
      final savedQueue = [_queueItem(id: 10)];
      final currentVideo = _track(id: 10);

      heartMode.getCurrentQueue = () => List.from(savedQueue);
      heartMode.getCurrentVideo = () => currentVideo;

      List<QueueItem>? restoredQueue;
      heartMode.onRestoreQueue = (queue, index, video) {
        restoredQueue = queue;
      };

      when(() => mockRecService.getRecommendations(tags: ['jazz']))
          .thenAnswer((_) async => []);

      await heartMode.activate(['jazz']);

      expect(heartMode.isHeartMode.value, isFalse);
      expect(restoredQueue, isNotNull);
    });

    test('restores queue on exception', () async {
      heartMode.getCurrentQueue = () => [_queueItem()];
      heartMode.getCurrentVideo = () => _track();

      List<QueueItem>? restoredQueue;
      heartMode.onRestoreQueue = (queue, index, video) {
        restoredQueue = queue;
      };

      when(() => mockRecService.getRecommendations(tags: any(named: 'tags')))
          .thenThrow(Exception('API error'));

      await heartMode.activate(['test']);

      expect(heartMode.isHeartMode.value, isFalse);
      expect(restoredQueue, isNotNull);
      expect(heartMode.isHeartModeLoading.value, isFalse);
    });
  });

  group('deactivate', () {
    test('sets pendingExit without immediately restoring', () {
      heartMode.isHeartMode.value = true;
      heartMode.heartModeTags.assignAll(['pop']);

      bool restoreCalled = false;
      heartMode.onRestoreQueue = (_, __, ___) => restoreCalled = true;

      heartMode.deactivate();

      expect(heartMode.pendingExit, isTrue);
      expect(heartMode.isHeartMode.value, isTrue); // still active
      expect(restoreCalled, isFalse); // not restored yet
    });
  });

  group('handleTrackCompleted', () {
    test('returns false when not pending exit', () {
      expect(heartMode.handleTrackCompleted(), isFalse);
    });

    test('returns true and restores queue when pending exit', () async {
      final savedQueue = [_queueItem(id: 5)];
      final savedVideo = _track(id: 5);

      heartMode.getCurrentQueue = () => List.from(savedQueue);
      heartMode.getCurrentVideo = () => savedVideo;

      when(() => mockRecService.getRecommendations(tags: ['test']))
          .thenAnswer((_) async => [_track(id: 99)]);

      heartMode.onPlayFromSearch = (video) async {};
      heartMode.onAddToQueueSilent = (_) async => true;

      await heartMode.activate(['test']);

      List<QueueItem>? restoredQueue;
      heartMode.onRestoreQueue = (queue, index, video) {
        restoredQueue = queue;
      };

      heartMode.deactivate();

      final handled = heartMode.handleTrackCompleted();

      expect(handled, isTrue);
      expect(heartMode.pendingExit, isFalse);
      expect(heartMode.isHeartMode.value, isFalse);
      expect(restoredQueue, isNotNull);
    });
  });

  group('autoNext', () {
    test('gets new recommendations and plays non-duplicate', () async {
      heartMode.isHeartMode.value = true;
      heartMode.heartModeTags.assignAll(['pop']);

      final currentQueue = [_queueItem(id: 1)];
      heartMode.getCurrentQueue = () => currentQueue;

      when(() => mockStorage.getPlayHistory()).thenReturn([]);

      final newSong = _track(id: 99, title: 'New Song');
      when(() => mockRecService.getRecommendations(
            tags: any(named: 'tags'),
            recentPlayed: any(named: 'recentPlayed'),
          )).thenAnswer((_) async => [newSong]);

      SearchVideoModel? playedVideo;
      heartMode.onPlayFromSearch = (video) async {
        playedVideo = video;
      };

      await heartMode.autoNext();

      expect(playedVideo, isNotNull);
      expect(playedVideo!.uniqueId, newSong.uniqueId);
      expect(heartMode.isHeartModeLoading.value, isFalse);
    });

    test('stops playback when no new recommendations', () async {
      heartMode.isHeartMode.value = true;
      heartMode.heartModeTags.assignAll(['pop']);

      final existingSong = _track(id: 1);
      final currentQueue = [
        QueueItem(video: existingSong, audioUrl: 'https://x.mp3'),
      ];
      heartMode.getCurrentQueue = () => currentQueue;

      when(() => mockStorage.getPlayHistory()).thenReturn([]);

      // Return only songs that are already in queue
      when(() => mockRecService.getRecommendations(
            tags: any(named: 'tags'),
            recentPlayed: any(named: 'recentPlayed'),
          )).thenAnswer((_) async => [existingSong]);

      bool stopCalled = false;
      heartMode.onStopPlayback = () => stopCalled = true;

      await heartMode.autoNext();

      expect(stopCalled, isTrue);
    });

    test('handles exception gracefully', () async {
      heartMode.isHeartMode.value = true;
      heartMode.heartModeTags.assignAll(['test']);
      heartMode.getCurrentQueue = () => [];

      when(() => mockStorage.getPlayHistory()).thenReturn([]);

      when(() => mockRecService.getRecommendations(
            tags: any(named: 'tags'),
            recentPlayed: any(named: 'recentPlayed'),
          )).thenThrow(Exception('network error'));

      bool stopCalled = false;
      heartMode.onStopPlayback = () => stopCalled = true;

      await heartMode.autoNext();

      expect(stopCalled, isTrue);
      expect(heartMode.isHeartModeLoading.value, isFalse);
    });
  });

  group('state cleanup', () {
    test('activate resets loading after completion', () async {
      heartMode.getCurrentQueue = () => [];
      heartMode.getCurrentVideo = () => null;
      heartMode.onPlayFromSearch = (_) async {};
      heartMode.onAddToQueueSilent = (_) async => true;

      when(() => mockRecService.getRecommendations(tags: ['x']))
          .thenAnswer((_) async => [_track()]);

      await heartMode.activate(['x']);

      expect(heartMode.isHeartModeLoading.value, isFalse);
    });

    test('toggle calls deactivate when heart mode is active', () {
      heartMode.isHeartMode.value = true;

      heartMode.toggle();

      expect(heartMode.pendingExit, isTrue);
    });

    test('toggle does nothing when heart mode is inactive', () {
      heartMode.isHeartMode.value = false;

      heartMode.toggle();

      expect(heartMode.pendingExit, isFalse);
    });
  });
}
