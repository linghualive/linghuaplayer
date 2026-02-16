import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import 'play_queue_sheet.dart';
import 'uploader_works_sheet.dart';

class PlayerControls extends GetView<PlayerController> {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Track title + quality badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.currentVideo.value?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      final author =
                          controller.currentVideo.value?.author ?? '';
                      if (author.isNotEmpty) {
                        UploaderWorksSheet.show();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            controller.currentVideo.value?.author ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                        if ((controller.currentVideo.value?.author ?? '')
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (controller.audioQualityLabel.value.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildQualityBadge(
                      context, controller.audioQualityLabel.value),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Seek slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.12),
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
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.position.value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                Text(
                  _formatDuration(controller.duration.value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 24,
                icon: Icon(
                  _playModeIcon(controller.playMode.value),
                  color: controller.playMode.value == PlayMode.sequential
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.primary,
                ),
                onPressed: controller.togglePlayMode,
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: controller.skipPrevious,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                height: 64,
                child: FilledButton(
                  onPressed: controller.togglePlay,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    controller.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: controller.skipNext,
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 24,
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: PlayQueueSheet.show,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Video/Audio toggle
          TextButton.icon(
            onPressed: controller.toggleVideoMode,
            icon: Icon(
              controller.isVideoMode.value
                  ? Icons.videocam
                  : Icons.music_note,
              size: 18,
            ),
            label: Text(
              controller.isVideoMode.value ? '视频模式' : '音频模式',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            style: TextButton.styleFrom(
              foregroundColor: controller.isVideoMode.value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    });
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
    }
  }

  Widget _buildQualityBadge(BuildContext context, String label) {
    final bool isPremium = label == 'Hi-Res' || label == 'Dolby';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPremium
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: isPremium
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
