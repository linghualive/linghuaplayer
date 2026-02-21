import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/modules/player/services/volume_normalization_service.dart';

void main() {
  late VolumeNormalizationService service;

  setUp(() {
    service = VolumeNormalizationService();
  });

  group('VolumeNormalizationService', () {
    test('disabled by default', () {
      expect(service.isEnabled, isFalse);
    });

    test('can be enabled and disabled', () {
      service.isEnabled = true;
      expect(service.isEnabled, isTrue);

      service.isEnabled = false;
      expect(service.isEnabled, isFalse);
    });

    test('returns 1.0 when disabled', () {
      service.isEnabled = false;

      final gain = service.getGainForSource('bilibili');
      expect(gain, 1.0);
    });

    test('returns source-specific gain when enabled', () {
      service.isEnabled = true;

      // Different sources may have different loudness characteristics
      final biliGain = service.getGainForSource('bilibili');
      final neteaseGain = service.getGainForSource('netease');

      // Both should be valid multipliers
      expect(biliGain, greaterThan(0.0));
      expect(neteaseGain, greaterThan(0.0));
    });

    test('clamps gain between min and max', () {
      service.isEnabled = true;

      final gain = service.getGainForSource('unknown_source');

      // Should be between sensible limits
      expect(gain, greaterThanOrEqualTo(VolumeNormalizationService.minGain));
      expect(gain, lessThanOrEqualTo(VolumeNormalizationService.maxGain));
    });

    test('unknown source returns neutral gain', () {
      service.isEnabled = true;

      final gain = service.getGainForSource('totally_unknown');
      expect(gain, 1.0); // neutral
    });
  });
}
