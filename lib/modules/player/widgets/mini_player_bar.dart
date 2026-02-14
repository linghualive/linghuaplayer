import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/widgets/cached_image.dart';
import '../player_controller.dart';

class MiniPlayerBar extends GetView<PlayerController> {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasCurrentTrack) {
        return const SizedBox.shrink();
      }

      final video = controller.currentVideo.value!;
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds /
              controller.duration.value.inMilliseconds
          : 0.0;

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.player),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CachedImage(
                      imageUrl: video.pic,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            video.author,
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
                        ],
                      ),
                    ),
                    if (controller.isLoading.value)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          controller.isPlaying.value
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: controller.togglePlay,
                      ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: controller.skipNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
