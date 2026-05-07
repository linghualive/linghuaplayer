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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  controller.currentVideo.value?.title ?? '',
                  key: ValueKey(controller.currentVideo.value?.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                  ),
                ),
              )),
        ),
        const SizedBox(height: 6),
        // Artist + quality
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Obx(() => Row(
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
                                key: ValueKey(
                                    controller.currentVideo.value?.author),
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
                              controller.currentVideo.value!.author
                                  .isNotEmpty)
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
              )),
        ),
        const SizedBox(height: 28),
        // Slider + Time labels (high-frequency: position/duration updates)
        Obx(() {
          final pos = controller.position.value;
          final dur = controller.duration.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                      elevation: 2,
                      pressedElevation: 4,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    thumbColor: theme.colorScheme.primary,
                    overlayColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: pos.inMilliseconds.toDouble().clamp(
                          0,
                          dur.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                        ),
                    max: dur.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    onChanged: (value) {
                      controller
                          .seekTo(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(pos),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _formatDuration(dur),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 20),
        // Main controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Output
                  _ControlIcon(
                    icon: _outputIcon(controller.audioOutput.activeType),
                    size: 21,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    tooltip: '输出',
                    onTap: () async {
                      await controller.audioOutput.showOutputPicker();
                      if (!controller.audioOutput.usesSystemPicker &&
                          controller.audioOutput.devices.isNotEmpty) {
                        AudioOutputSheet.show();
                      }
                    },
                  ),
                  if (PlatformUtils.isDesktop) ...[
                    const SizedBox(width: 20),
                    _ControlIcon(
                      icon: Icons.skip_previous_rounded,
                      size: 30,
                      onTap: () => controller.skipPrevious(),
                    ),
                  ] else
                    const SizedBox(width: 28),
                  // Play/Pause button
                  _PlayButton(
                    isPlaying: controller.isPlaying.value,
                    isLoading: controller.isLoading.value,
                    primaryColor: theme.colorScheme.primary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.togglePlay();
                    },
                  ),
                  if (PlatformUtils.isDesktop) ...[
                    const SizedBox(width: 20),
                    _ControlIcon(
                      icon: Icons.skip_next_rounded,
                      size: 30,
                      onTap: () => controller.skipNext(),
                    ),
                  ] else
                    const SizedBox(width: 28),
                  // Play mode
                  _ControlIcon(
                    icon: _playModeIcon(controller.playMode.value),
                    size: 21,
                    color: controller.playMode.value == PlayMode.sequential
                        ? theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6)
                        : theme.colorScheme.primary,
                    tooltip: _playModeLabel(controller.playMode.value),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.togglePlayMode();
                    },
                  ),
                ],
              )),
        ),
        const SizedBox(height: 12),
        // Queue button
        Obx(() => _QueueButton(
              count: controller.queue.length,
              onTap: PlayQueueSheet.show,
            )),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isPremium
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
            : theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPremium
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPremium
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isPremium ? FontWeight.w600 : FontWeight.w500,
          fontSize: 10,
          letterSpacing: 0.3,
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

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final Color primaryColor;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isLoading
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
              onPressed: onTap,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: 36,
                ),
              ),
            ),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final String? tooltip;
  final VoidCallback onTap;

  const _ControlIcon({
    required this.icon,
    required this.size,
    this.color,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    );
  }
}

class _QueueButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _QueueButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.queue_music_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 5),
              Text(
                '播放队列',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
