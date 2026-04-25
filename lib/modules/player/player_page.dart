import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/platform_utils.dart';
import '../../shared/widgets/fav_panel.dart';
import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_lyrics.dart';
import 'widgets/swipeable_player_body.dart';

class PlayerPage extends GetView<PlayerController> {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final video = controller.currentVideo.value;
            if (video == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: '收藏到歌单',
              onPressed: () => FavPanel.show(context, video),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        final dynamicColor = controller.coverColor.value;
        final topColor = dynamicColor?.withValues(alpha: 0.35) ??
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3);
        final bottomColor = Theme.of(context).colorScheme.surface;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.currentVideo.value == null) {
                return const Center(child: Text('未选择曲目'));
              }

              if (PlatformUtils.isDesktop) {
                return _buildDesktopLayout();
              }
              return _buildMobileLayout();
            }),
          ),
        );
      }),
    );
  }

  Widget _buildArtworkArea() {
    return Obx(() {
      return GestureDetector(
        onTap: () => controller.toggleLyricsView(),
        child: controller.showLyrics.value
            ? const PlayerLyrics()
            : const PlayerArtwork(),
      );
    });
  }

  Widget _buildMobileLayout() {
    return SwipeablePlayerBody(
      buildArtworkArea: _buildArtworkArea,
      controlsArea: const PlayerControls(),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _buildArtworkArea(),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const PlayerControls(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
