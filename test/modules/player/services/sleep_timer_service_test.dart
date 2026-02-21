import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/sleep_timer_service.dart';

void main() {
  late SleepTimerService service;

  setUp(() {
    service = SleepTimerService();
  });

  tearDown(() {
    service.cancel();
  });

  group('SleepTimerService', () {
    test('starts inactive', () {
      expect(service.isActive, isFalse);
      expect(service.remainingDuration, Duration.zero);
    });

    test('startTimer activates with given duration', () {
      service.startTimer(const Duration(minutes: 15));

      expect(service.isActive, isTrue);
      expect(service.remainingDuration.inMinutes, 15);
    });

    test('cancel deactivates timer', () {
      service.startTimer(const Duration(minutes: 30));
      service.cancel();

      expect(service.isActive, isFalse);
      expect(service.remainingDuration, Duration.zero);
    });

    test('tick decrements remaining time by 1 second', () {
      service.startTimer(const Duration(seconds: 10));

      service.tick();
      expect(service.remainingDuration.inSeconds, 9);

      service.tick();
      expect(service.remainingDuration.inSeconds, 8);
    });

    test('timer expires and triggers callback', () {
      bool expired = false;
      service.onTimerExpired = () => expired = true;

      service.startTimer(const Duration(seconds: 2));

      service.tick();
      expect(expired, isFalse);

      service.tick();
      expect(expired, isTrue);
      expect(service.isActive, isFalse);
    });

    test('startEndOfTrack sets mode to endOfTrack', () {
      service.startEndOfTrack();

      expect(service.isActive, isTrue);
      expect(service.mode, SleepTimerMode.endOfTrack);
    });

    test('onTrackCompleted triggers callback in endOfTrack mode', () {
      bool expired = false;
      service.onTimerExpired = () => expired = true;

      service.startEndOfTrack();
      service.onTrackCompleted();

      expect(expired, isTrue);
      expect(service.isActive, isFalse);
    });

    test('onTrackCompleted does nothing in timed mode', () {
      bool expired = false;
      service.onTimerExpired = () => expired = true;

      service.startTimer(const Duration(minutes: 5));
      service.onTrackCompleted();

      expect(expired, isFalse);
    });

    test('startEndOfNTracks counts down tracks', () {
      bool expired = false;
      service.onTimerExpired = () => expired = true;

      service.startEndOfNTracks(3);

      expect(service.isActive, isTrue);
      expect(service.mode, SleepTimerMode.endOfNTracks);
      expect(service.remainingTracks, 3);

      service.onTrackCompleted();
      expect(service.remainingTracks, 2);
      expect(expired, isFalse);

      service.onTrackCompleted();
      expect(service.remainingTracks, 1);
      expect(expired, isFalse);

      service.onTrackCompleted();
      expect(service.remainingTracks, 0);
      expect(expired, isTrue);
      expect(service.isActive, isFalse);
    });

    test('onPlayStateChanged pauses timer when not playing', () {
      service.startTimer(const Duration(seconds: 10));

      service.onPlayStateChanged(false); // paused
      final before = service.remainingDuration;

      service.tick(); // should be no-op when paused

      expect(service.remainingDuration, before);
    });

    test('onPlayStateChanged resumes timer when playing', () {
      service.startTimer(const Duration(seconds: 10));
      service.onPlayStateChanged(false); // pause
      service.onPlayStateChanged(true); // resume

      service.tick();
      expect(service.remainingDuration.inSeconds, 9);
    });

    test('only one timer at a time', () {
      service.startTimer(const Duration(minutes: 5));
      service.startTimer(const Duration(minutes: 10));

      // Second timer replaces first
      expect(service.remainingDuration.inMinutes, 10);
    });
  });
}
