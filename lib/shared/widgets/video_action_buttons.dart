import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.playlist_add_rounded, size: 20, color: iconColor),
          tooltip: '添加到播放列表',
          onPressed: () {
            final player = Get.find<PlayerController>();
            player.addToQueue(video);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          splashRadius: 18,
        ),
        IconButton(
          icon: Icon(Icons.favorite_border_rounded, size: 20, color: iconColor),
          tooltip: '收藏到歌单',
          onPressed: () => FavPanel.show(context, video),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          splashRadius: 18,
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
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.playlist_add_rounded, size: 20, color: iconColor),
          tooltip: '添加到播放列表',
          onPressed: () {
            final player = Get.find<PlayerController>();
            player.addToQueue(video);
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          splashRadius: 18,
        ),
        IconButton(
          icon: Icon(Icons.favorite_border_rounded, size: 20, color: iconColor),
          tooltip: '收藏到歌单',
          onPressed: () => FavPanel.show(context, video),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          splashRadius: 18,
        ),
      ],
    );
  }
}
