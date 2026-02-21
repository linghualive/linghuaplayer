import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

/// An enhanced seek slider with drag preview and buffered progress.
///
/// While dragging, the position label updates in real-time without
/// actually seeking until the drag is released.
class SeekSlider extends StatefulWidget {
  const SeekSlider({super.key});

  /// Format a duration as mm:ss or h:mm:ss.
  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  State<SeekSlider> createState() => _SeekSliderState();
}

class _SeekSliderState extends State<SeekSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final position = controller.position.value;
      final duration = controller.duration.value;
      final totalMs = duration.inMilliseconds.toDouble();

      final displayPosition = _isDragging
          ? Duration(milliseconds: (_dragValue * totalMs).round())
          : position;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
            ),
            child: Slider(
              value: _isDragging
                  ? _dragValue.clamp(0.0, 1.0)
                  : (totalMs > 0
                      ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                      : 0.0),
              onChangeStart: (_) {
                setState(() => _isDragging = true);
              },
              onChanged: (value) {
                setState(() => _dragValue = value);
              },
              onChangeEnd: (value) {
                setState(() => _isDragging = false);
                final seekPos = Duration(
                  milliseconds: (value * totalMs).round(),
                );
                controller.seekTo(seekPos);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  SeekSlider.formatDuration(displayPosition),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                Text(
                  SeekSlider.formatDuration(duration),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
