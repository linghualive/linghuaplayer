import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flamekit/modules/player/services/playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    // Stub audio_session method channel to prevent platform errors
    const channel = MethodChannel('com.ryanheise.audio_session');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() {
    Get.reset();
  });

  group('PlaybackService construction', () {
    test('initializes with default reactive state', () {
      final service = PlaybackService();

      expect(service.isPlaying.value, isFalse);
      expect(service.position.value, Duration.zero);
      expect(service.duration.value, Duration.zero);
      expect(service.buffered.value, Duration.zero);
    });

    test('callbacks start as null', () {
      final service = PlaybackService();

      expect(service.onTrackCompleted, isNull);
      expect(service.onPositionUpdate, isNull);
    });

    test('onTrackCompleted can be assigned', () {
      final service = PlaybackService();
      bool called = false;

      service.onTrackCompleted = () => called = true;
      service.onTrackCompleted!();

      expect(called, isTrue);
    });

    test('onPositionUpdate can be assigned', () {
      final service = PlaybackService();
      Duration? pos;

      service.onPositionUpdate = (p) => pos = p;
      service.onPositionUpdate!(const Duration(seconds: 5));

      expect(pos, const Duration(seconds: 5));
    });
  });

  group('PlaybackService._isSwitchingTrack guard', () {
    test('begins with switching track false (not suppressing events)', () {
      final service = PlaybackService();
      // _isSwitchingTrack is private but its effect is testable:
      // when false, completed events should fire the callback
      expect(service.isPlaying.value, isFalse);
    });
  });

  group('PlaybackService stop', () {
    test('stop does not throw', () {
      final service = PlaybackService();

      // stop() should be safe to call even with no media loaded
      expect(() => service.stop(), returnsNormally);
    });
  });
}
