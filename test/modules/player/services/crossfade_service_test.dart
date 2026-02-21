import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/crossfade_service.dart';

void main() {
  late CrossfadeService service;

  setUp(() {
    service = CrossfadeService();
  });

  tearDown(() {
    service.cancel();
  });

  group('crossfade configuration', () {
    test('defaults to disabled (0 seconds)', () {
      expect(service.crossfadeDuration, Duration.zero);
      expect(service.isEnabled, isFalse);
    });

    test('setting duration enables crossfade', () {
      service.crossfadeDuration = const Duration(seconds: 5);

      expect(service.isEnabled, isTrue);
      expect(service.crossfadeDuration, const Duration(seconds: 5));
    });

    test('setting to zero disables crossfade', () {
      service.crossfadeDuration = const Duration(seconds: 5);
      service.crossfadeDuration = Duration.zero;

      expect(service.isEnabled, isFalse);
    });

    test('clamps duration to max 12 seconds', () {
      service.crossfadeDuration = const Duration(seconds: 20);

      expect(service.crossfadeDuration, const Duration(seconds: 12));
    });
  });

  group('shouldStartCrossfade', () {
    test('returns false when disabled', () {
      service.crossfadeDuration = Duration.zero;

      expect(
        service.shouldStartCrossfade(
          position: const Duration(seconds: 170),
          duration: const Duration(seconds: 180),
        ),
        isFalse,
      );
    });

    test('returns true when remaining time equals crossfade duration', () {
      service.crossfadeDuration = const Duration(seconds: 5);

      expect(
        service.shouldStartCrossfade(
          position: const Duration(seconds: 175),
          duration: const Duration(seconds: 180),
        ),
        isTrue,
      );
    });

    test('returns false when still far from end', () {
      service.crossfadeDuration = const Duration(seconds: 5);

      expect(
        service.shouldStartCrossfade(
          position: const Duration(seconds: 100),
          duration: const Duration(seconds: 180),
        ),
        isFalse,
      );
    });

    test('skips when track duration < 2x crossfade duration', () {
      service.crossfadeDuration = const Duration(seconds: 10);

      // Track is only 15s, which is < 2 * 10s = 20s
      expect(
        service.shouldStartCrossfade(
          position: const Duration(seconds: 5),
          duration: const Duration(seconds: 15),
        ),
        isFalse,
      );
    });

    test('works when track duration is exactly 2x crossfade', () {
      service.crossfadeDuration = const Duration(seconds: 5);

      // Track is exactly 10s = 2 * 5s, should be allowed
      expect(
        service.shouldStartCrossfade(
          position: const Duration(seconds: 5),
          duration: const Duration(seconds: 10),
        ),
        isTrue,
      );
    });
  });

  group('calculateVolumes', () {
    test('returns full volumes when disabled', () {
      service.crossfadeDuration = Duration.zero;

      final volumes = service.calculateVolumes(
        position: const Duration(seconds: 170),
        duration: const Duration(seconds: 180),
      );

      expect(volumes.currentVolume, 1.0);
      expect(volumes.nextVolume, 0.0);
    });

    test('calculates linear fade at midpoint', () {
      service.crossfadeDuration = const Duration(seconds: 10);

      final volumes = service.calculateVolumes(
        position: const Duration(seconds: 175),
        duration: const Duration(seconds: 180),
      );

      // 5s remaining out of 10s crossfade = 50%
      expect(volumes.currentVolume, closeTo(0.5, 0.01));
      expect(volumes.nextVolume, closeTo(0.5, 0.01));
    });

    test('current fully faded at track end', () {
      service.crossfadeDuration = const Duration(seconds: 10);

      final volumes = service.calculateVolumes(
        position: const Duration(seconds: 180),
        duration: const Duration(seconds: 180),
      );

      expect(volumes.currentVolume, closeTo(0.0, 0.01));
      expect(volumes.nextVolume, closeTo(1.0, 0.01));
    });
  });

  group('cancel', () {
    test('resets crossfade state', () {
      service.crossfadeDuration = const Duration(seconds: 5);

      service.cancel();

      // Duration setting persists, but any active crossfade is cancelled
      expect(service.isEnabled, isTrue); // setting persists
    });
  });
}
