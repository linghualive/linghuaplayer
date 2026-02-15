import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../shared/utils/app_toast.dart';
import '../../shared/widgets/fav_panel.dart';
import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_lyrics.dart';
import 'widgets/player_video.dart';
import 'widgets/play_queue_sheet.dart';

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
            if (video == null || video.id <= 0 || video.isNetease) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: '收藏',
              onPressed: () {
                final storage = Get.find<StorageService>();
                if (!storage.isLoggedIn) {
                  AppToast.show('请先登录哔哩哔哩');
                  return;
                }
                FavPanel.show(context, video.id);
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: PlayQueueSheet.show,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.currentVideo.value == null) {
              return const Center(child: Text('未选择曲目'));
            }

            return Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  flex: 5,
                  child: Obx(() {
                    if (controller.isVideoMode.value) {
                      return const PlayerVideo();
                    }
                    return GestureDetector(
                      onTap: () => controller.toggleLyricsView(),
                      child: controller.showLyrics.value
                          ? const PlayerLyrics()
                          : const PlayerArtwork(),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                const Expanded(flex: 4, child: PlayerControls()),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }
}
