import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/widgets/cached_image.dart';
import '../player_controller.dart';
import 'play_queue_sheet.dart';

class MiniPlayerBar extends GetView<PlayerController> {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasTrack = controller.hasCurrentTrack;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: hasTrack
            ? _buildBar(context)
            : const SizedBox.shrink(key: ValueKey('empty')),
      );
    });
  }

  Widget _buildBar(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final video = controller.currentVideo.value!;
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds /
              controller.duration.value.inMilliseconds
          : 0.0;
      final coverColor = controller.coverColor.value;

      return GestureDetector(
        key: const ValueKey('mini_player'),
        onTap: () => Get.toNamed(AppRoutes.player),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.12),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (coverColor ?? Colors.black).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
                child: Row(
                  children: [
                    // Cover art with subtle glow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: coverColor != null
                            ? [
                                BoxShadow(
                                  color: coverColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CachedImage(
                          imageUrl: video.pic,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title + author
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    if (controller.isLoading.value)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(controller.isPlaying.value),
                            size: 26,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.togglePlay();
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 22),
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              controller.skipNext();
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded, size: 20),
                      onPressed: PlayQueueSheet.show,
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 2,
                    backgroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
      );
    });
  }
}
