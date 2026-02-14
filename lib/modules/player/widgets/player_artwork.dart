import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cached_image.dart';
import '../player_controller.dart';

class PlayerArtwork extends GetView<PlayerController> {
  const PlayerArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final video = controller.currentVideo.value;
      if (video == null) return const SizedBox.shrink();

      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedImage(
                imageUrl: video.pic,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    });
  }
}
