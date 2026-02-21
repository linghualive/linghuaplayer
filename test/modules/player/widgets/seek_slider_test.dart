import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/widgets/seek_slider.dart';

void main() {
  group('SeekSliderState logic', () {
    test('formatDuration formats zero correctly', () {
      expect(SeekSlider.formatDuration(Duration.zero), '0:00');
    });

    test('formatDuration formats seconds', () {
      expect(SeekSlider.formatDuration(const Duration(seconds: 5)), '0:05');
    });

    test('formatDuration formats minutes and seconds', () {
      expect(SeekSlider.formatDuration(const Duration(minutes: 3, seconds: 42)), '3:42');
    });

    test('formatDuration formats hours', () {
      expect(
        SeekSlider.formatDuration(const Duration(hours: 1, minutes: 5, seconds: 3)),
        '1:05:03',
      );
    });

    test('formatDuration handles large durations', () {
      expect(
        SeekSlider.formatDuration(const Duration(hours: 10, minutes: 30, seconds: 0)),
        '10:30:00',
      );
    });
  });
}
