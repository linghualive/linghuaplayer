import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/desktop_theme.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../player/player_controller.dart';
import '../../player/widgets/play_queue_sheet.dart';

/// Desktop player bar that shows at the bottom of the screen
class DesktopPlayerBar extends GetView<PlayerController> {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: DesktopTheme.desktopPlayerBarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        if (!controller.hasCurrentTrack) {
          return _buildEmptyPlayer(context);
        }

        final video = controller.currentVideo.value!;
        final isPlaying = controller.isPlaying.value;
        final position = controller.position.value;
        final duration = controller.duration.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Track info section
              SizedBox(
                width: 300,
                child: _buildTrackInfo(context, video),
              ),
              // Player controls section
              Expanded(
                child: _buildPlayerControls(
                  context,
                  isPlaying,
                  position,
                  duration,
                ),
              ),
              // Extra controls section
              SizedBox(
                width: 200,
                child: _buildExtraControls(context),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyPlayer(BuildContext context) {
    return Center(
      child: Text(
        '暂无播放内容',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, dynamic video) {
    return InkWell(
      onTap: () => Get.toNamed('/player'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedImage(
                imageUrl: video.pic ?? '',
                width: 44,
                height: 44,
              ),
            ),
            const SizedBox(width: 12),
            // Track details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.author ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls(
    BuildContext context,
    bool isPlaying,
    Duration position,
    Duration duration,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: controller.skipPrevious,
              iconSize: 24,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 8),
            // Play/Pause button
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: controller.togglePlay,
                iconSize: 22,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: controller.skipNext,
              iconSize: 24,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        // Progress bar with time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                _formatDuration(position),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 16,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble(),
                      min: 0,
                      max: duration.inSeconds.toDouble().clamp(0.1, double.infinity),
                      onChanged: (value) {
                        controller.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Play mode button
        IconButton(
          icon: Icon(
            controller.playMode.value == PlayMode.shuffle
                ? Icons.shuffle
                : controller.playMode.value == PlayMode.repeatOne
                    ? Icons.repeat_one
                    : Icons.repeat,
          ),
          onPressed: controller.togglePlayMode,
          color: controller.playMode.value != PlayMode.sequential
              ? Theme.of(context).colorScheme.primary
              : null,
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          tooltip: _getPlayModeTooltip(),
        ),
        // Queue button
        IconButton(
          icon: Badge(
            label: Text(
              '${controller.queue.length}',
              style: const TextStyle(fontSize: 10),
            ),
            isLabelVisible: controller.queue.isNotEmpty,
            child: const Icon(Icons.queue_music),
          ),
          onPressed: () => _showPlayQueue(context),
          tooltip: '播放队列',
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Favorite button
        IconButton(
          icon: const Icon(Icons.favorite_outline),
          onPressed: () {
            // TODO: Implement favorite functionality
          },
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        // Full screen button
        IconButton(
          icon: const Icon(Icons.open_in_full),
          onPressed: () => Get.toNamed('/player'),
          tooltip: '全屏播放器',
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  String _getPlayModeTooltip() {
    switch (controller.playMode.value) {
      case PlayMode.sequential:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.repeatOne:
        return '单曲循环';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showPlayQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayQueueSheet(),
    );
  }
}