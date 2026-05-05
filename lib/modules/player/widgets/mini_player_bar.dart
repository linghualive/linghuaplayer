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

      final video = controller.currentVideo.value!;
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds /
              controller.duration.value.inMilliseconds
          : 0.0;

      return GestureDetector(
        key: const ValueKey('mini_player'),
        onTap: () => Get.toNamed(AppRoutes.player),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
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
                padding:
                    const EdgeInsets.fromLTRB(10, 8, 4, 6),
                child: Row(
                  children: [
                    // Cover art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: video.pic,
                        width: 44,
                        height: 44,
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            video.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
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
                        icon: Icon(
                          controller.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.togglePlay();
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 24),
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              controller.skipNext();
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music, size: 22),
                      onPressed: PlayQueueSheet.show,
                      visualDensity: VisualDensity.compact,
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
                    minHeight: 2.5,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
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
