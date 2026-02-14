import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/search_video_model.dart';
import '../../modules/player/player_controller.dart';
import 'fav_panel.dart';

/// Reusable action buttons for adding a video to queue and opening the
/// favorite panel. Use [VideoActionRow] for horizontal layout (e.g. overlay
/// on grid cards) and [VideoActionColumn] for vertical layout (e.g. trailing
/// in list rows).
class VideoActionColumn extends StatelessWidget {
  final SearchVideoModel video;

  const VideoActionColumn({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.playlist_add, size: 20),
          tooltip: '添加到播放列表',
          onPressed: () {
            final player = Get.find<PlayerController>();
            player.addToQueue(video);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 20),
          tooltip: '收藏',
          onPressed: () {
            final storage = Get.find<StorageService>();
            if (!storage.isLoggedIn) {
              Get.snackbar('提示', '请先登录',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            FavPanel.show(context, video.id);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class VideoActionRow extends StatelessWidget {
  final SearchVideoModel video;

  const VideoActionRow({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.playlist_add, size: 20),
          tooltip: '添加到播放列表',
          onPressed: () {
            final player = Get.find<PlayerController>();
            player.addToQueue(video);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 20),
          tooltip: '收藏',
          onPressed: () {
            final storage = Get.find<StorageService>();
            if (!storage.isLoggedIn) {
              Get.snackbar('提示', '请先登录',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            FavPanel.show(context, video.id);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
