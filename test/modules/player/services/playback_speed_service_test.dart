import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/playback_speed_service.dart';

void main() {
  late PlaybackSpeedService service;

  setUp(() {
    service = PlaybackSpeedService();
  });

  group('PlaybackSpeedService', () {
    test('defaults to 1.0x', () {
      expect(service.speed, 1.0);
    });

    test('supports standard speed values', () {
      for (final speed in PlaybackSpeedService.supportedSpeeds) {
        service.setSpeed(speed);
        expect(service.speed, speed);
      }
    });

    test('supported speeds are 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x', () {
      expect(
        PlaybackSpeedService.supportedSpeeds,
        [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
      );
    });

    test('rejects unsupported speed values', () {
      service.setSpeed(3.0);

      expect(service.speed, 1.0); // unchanged
    });

    test('speed persists across method calls', () {
      service.setSpeed(1.5);
      expect(service.speed, 1.5);

      // Other operations shouldn't reset speed
      expect(service.speed, 1.5);
    });

    test('cycleSpeed advances to next speed', () {
      expect(service.speed, 1.0);

      service.cycleSpeed();
      expect(service.speed, 1.25);

      service.cycleSpeed();
      expect(service.speed, 1.5);

      service.cycleSpeed();
      expect(service.speed, 2.0);

      service.cycleSpeed();
      expect(service.speed, 0.5); // wraps around

      service.cycleSpeed();
      expect(service.speed, 0.75);

      service.cycleSpeed();
      expect(service.speed, 1.0); // back to start
    });

    test('speedLabel returns formatted string', () {
      service.setSpeed(1.0);
      expect(service.speedLabel, '1.0x');

      service.setSpeed(1.5);
      expect(service.speedLabel, '1.5x');

      service.setSpeed(0.75);
      expect(service.speedLabel, '0.75x');
    });
  });
}
