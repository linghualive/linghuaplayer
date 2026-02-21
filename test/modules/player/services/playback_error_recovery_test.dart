import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/playback_error_recovery_service.dart';

void main() {
  late PlaybackErrorRecoveryService service;

  setUp(() {
    service = PlaybackErrorRecoveryService();
  });

  tearDown(() {
    service.cancel();
  });

  group('retryWithBackoff', () {
    test('succeeds on first attempt without retry', () async {
      int attempts = 0;
      final result = await service.retryWithBackoff(
        playAction: () async {
          attempts++;
        },
        reResolveAction: () async {},
      );

      expect(result, isTrue);
      expect(attempts, 1);
    });

    test('retries on transient error and succeeds on second attempt', () async {
      int attempts = 0;
      final result = await service.retryWithBackoff(
        playAction: () async {
          attempts++;
          if (attempts < 2) throw Exception('transient error');
        },
        reResolveAction: () async {},
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, isTrue);
      expect(attempts, 2);
    });

    test('calls onGiveUp after max retries', () async {
      int attempts = 0;
      bool gaveUp = false;

      final result = await service.retryWithBackoff(
        playAction: () async {
          attempts++;
          throw Exception('persistent error');
        },
        reResolveAction: () async {},
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 10),
        onGiveUp: () => gaveUp = true,
      );

      expect(result, isFalse);
      expect(attempts, 3);
      expect(gaveUp, isTrue);
    });

    test('applies exponential backoff delays', () async {
      final attemptTimes = <DateTime>[];

      final result = await service.retryWithBackoff(
        playAction: () async {
          attemptTimes.add(DateTime.now());
          if (attemptTimes.length < 3) throw Exception('fail');
        },
        reResolveAction: () async {},
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 50),
      );

      expect(result, isTrue);
      expect(attemptTimes.length, 3);

      // Verify delays increase (with some tolerance for execution time)
      if (attemptTimes.length >= 3) {
        final delay1 = attemptTimes[1].difference(attemptTimes[0]);
        final delay2 = attemptTimes[2].difference(attemptTimes[1]);
        // Second delay should be roughly 2x the first
        expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds));
      }
    });

    test('calls reResolveAction before retry', () async {
      int resolveCount = 0;
      int playCount = 0;

      await service.retryWithBackoff(
        playAction: () async {
          playCount++;
          if (playCount < 2) throw Exception('need re-resolve');
        },
        reResolveAction: () async {
          resolveCount++;
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(resolveCount, 1); // Called once before retry
      expect(playCount, 2);
    });

    test('cancel stops retry loop', () async {
      int attempts = 0;

      // Start retry in background
      final future = service.retryWithBackoff(
        playAction: () async {
          attempts++;
          throw Exception('keep failing');
        },
        reResolveAction: () async {},
        maxRetries: 10,
        initialDelay: const Duration(milliseconds: 50),
      );

      // Cancel after a short delay
      await Future.delayed(const Duration(milliseconds: 80));
      service.cancel();

      final result = await future;

      expect(result, isFalse);
      // Should have attempted fewer than maxRetries
      expect(attempts, lessThan(10));
    });

    test('format error skips retry and gives up immediately', () async {
      int attempts = 0;
      bool gaveUp = false;

      final result = await service.retryWithBackoff(
        playAction: () async {
          attempts++;
          throw FormatException('unsupported codec');
        },
        reResolveAction: () async {},
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 10),
        onGiveUp: () => gaveUp = true,
      );

      expect(result, isFalse);
      expect(attempts, 1); // No retry for format errors
      expect(gaveUp, isTrue);
    });
  });
}
