import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

class PlayerControls extends GetView<PlayerController> {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // Track title + quality badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  controller.currentVideo.value?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.currentVideo.value?.author ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    if (controller.audioQualityLabel.value.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildQualityBadge(
                          context, controller.audioQualityLabel.value),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Seek slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              thumbColor: Theme.of(context).colorScheme.primary,
            ),
            child: Slider(
              value: controller.position.value.inMilliseconds
                  .toDouble()
                  .clamp(
                    0,
                    controller.duration.value.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                  ),
              max: controller.duration.value.inMilliseconds
                  .toDouble()
                  .clamp(1, double.infinity),
              onChanged: (value) {
                controller.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.position.value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDuration(controller.duration.value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_previous),
                onPressed: controller.skipPrevious,
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: controller.togglePlay,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: Icon(
                  controller.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next),
                onPressed: controller.skipNext,
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildQualityBadge(BuildContext context, String label) {
    final bool isPremium =
        label == 'Hi-Res' || label == 'Dolby';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPremium
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: isPremium
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 0.5,
              )
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPremium
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal,
              fontSize: 10,
            ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
