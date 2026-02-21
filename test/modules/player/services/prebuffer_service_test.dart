import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/prebuffer_service.dart';

void main() {
  late PrebufferService service;

  setUp(() {
    service = PrebufferService();
  });

  tearDown(() {
    service.cancel();
  });

  group('prebufferNext', () {
    test('sets hasPrebufferedTrack after successful prebuffer', () async {
      await service.prebufferNext(
        resolveUrl: () async => 'https://audio.com/next.mp3',
      );

      expect(service.hasPrebufferedTrack, isTrue);
      expect(service.prebufferedUrl, 'https://audio.com/next.mp3');
    });

    test('hasPrebufferedTrack is false initially', () {
      expect(service.hasPrebufferedTrack, isFalse);
      expect(service.prebufferedUrl, isNull);
    });

    test('URL resolve failure sets hasPrebufferedTrack false', () async {
      await service.prebufferNext(
        resolveUrl: () async => throw Exception('network error'),
      );

      expect(service.hasPrebufferedTrack, isFalse);
    });

    test('only one prebuffer at a time', () async {
      // Start first prebuffer
      final future1 = service.prebufferNext(
        resolveUrl: () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'https://audio.com/first.mp3';
        },
      );

      // Start second prebuffer (should cancel first)
      final future2 = service.prebufferNext(
        resolveUrl: () async {
          return 'https://audio.com/second.mp3';
        },
      );

      await Future.wait([future1, future2]);

      // Last one wins
      expect(service.prebufferedUrl, 'https://audio.com/second.mp3');
    });

    test('cancel clears prebuffered state', () async {
      await service.prebufferNext(
        resolveUrl: () async => 'https://audio.com/next.mp3',
      );

      expect(service.hasPrebufferedTrack, isTrue);

      service.cancel();

      expect(service.hasPrebufferedTrack, isFalse);
      expect(service.prebufferedUrl, isNull);
    });
  });

  group('consumePrebuffered', () {
    test('returns URL and clears state', () async {
      await service.prebufferNext(
        resolveUrl: () async => 'https://audio.com/ready.mp3',
      );

      final url = service.consumePrebuffered();

      expect(url, 'https://audio.com/ready.mp3');
      expect(service.hasPrebufferedTrack, isFalse);
      expect(service.prebufferedUrl, isNull);
    });

    test('returns null when nothing prebuffered', () {
      final url = service.consumePrebuffered();

      expect(url, isNull);
    });
  });
}
