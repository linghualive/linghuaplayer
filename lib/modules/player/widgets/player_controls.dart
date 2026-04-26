import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/utils/platform_utils.dart';
import '../player_controller.dart';
import '../services/audio_output_service.dart';
import 'audio_output_sheet.dart';
import 'play_queue_sheet.dart';
import 'uploader_works_sheet.dart';

class PlayerControls extends GetView<PlayerController> {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                controller.currentVideo.value?.title ?? '',
                key: ValueKey(controller.currentVideo.value?.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Artist + quality
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final video = controller.currentVideo.value;
                      if (video != null &&
                          video.author.isNotEmpty &&
                          controller.uploaderMid.value > 0) {
                        UploaderWorksSheet.show();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              controller.currentVideo.value?.author ?? '',
                              key: ValueKey(controller.currentVideo.value?.author),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (controller.currentVideo.value != null &&
                            controller.uploaderMid.value > 0 &&
                            controller.currentVideo.value!.author.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 28),
          // Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.1),
                thumbColor: theme.colorScheme.primary,
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
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(controller.position.value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDuration(controller.duration.value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Main controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: PlatformUtils.isDesktop
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 22,
                  icon: Icon(
                    _outputIcon(controller.audioOutput.activeType),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: '输出',
                  onPressed: () async {
                    await controller.audioOutput.showOutputPicker();
                    if (!controller.audioOutput.usesSystemPicker &&
                        controller.audioOutput.devices.isNotEmpty) {
                      AudioOutputSheet.show();
                    }
                  },
                ),
                if (PlatformUtils.isDesktop)
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => controller.skipPrevious(),
                  ),
                if (!PlatformUtils.isDesktop) const SizedBox(width: 32),
                SizedBox(
                  width: 68,
                  height: 68,
                  child: controller.isLoading.value
                      ? FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.togglePlay();
                          },
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                          ),
                        ),
                ),
                if (PlatformUtils.isDesktop)
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => controller.skipNext(),
                  ),
                if (!PlatformUtils.isDesktop) const SizedBox(width: 32),
                IconButton(
                  iconSize: 22,
                  icon: Icon(
                    _playModeIcon(controller.playMode.value),
                    color: controller.playMode.value == PlayMode.sequential
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                  tooltip: _playModeLabel(controller.playMode.value),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.togglePlayMode();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Queue button
          TextButton.icon(
            onPressed: PlayQueueSheet.show,
            icon: const Icon(Icons.queue_music_rounded, size: 18),
            label: Text(
              '播放队列 (${controller.queue.length})',
              style: theme.textTheme.labelSmall,
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
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

  String _playModeLabel(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.repeatOne:
        return '单曲循环';
    }
  }

  IconData _outputIcon(AudioOutputType type) {
    switch (type) {
      case AudioOutputType.speaker:
        return Icons.volume_up_outlined;
      case AudioOutputType.bluetooth:
        return Icons.bluetooth_audio;
      case AudioOutputType.wired:
        return Icons.headphones;
      case AudioOutputType.airplay:
        return Icons.airplay;
      case AudioOutputType.usb:
        return Icons.usb;
      case AudioOutputType.hdmi:
        return Icons.settings_input_hdmi;
      case AudioOutputType.unknown:
        return Icons.volume_up_outlined;
    }
  }

  Widget _buildQualityBadge(BuildContext context, String label) {
    final theme = Theme.of(context);
    final bool isPremium = label == 'Hi-Res' || label == 'Dolby';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPremium
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: isPremium
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 0.5,
              )
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPremium
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
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
