import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/storage_service.dart';
import '../../../data/models/recommend/rec_video_item_model.dart';
import '../../../modules/player/player_controller.dart';
import '../../../shared/utils/duration_formatter.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/fav_panel.dart';

class VideoCardV extends StatelessWidget {
  final RecVideoItemModel video;
  final VoidCallback? onTap;

  const VideoCardV({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with duration badge
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: video.pic.startsWith('//')
                        ? 'https:${video.pic}'
                        : video.pic,
                  ),
                  // Duration badge
                  if (video.duration > 0)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DurationFormatter.format(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title + more button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              _MoreButton(video: video),
            ],
          ),
          const SizedBox(height: 3),
          // Author + stats
          Text(
            '${video.owner.name}  ${_formatCount(video.stat.view)}  ${_formatCount(video.stat.danmaku)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}

class _MoreButton extends StatelessWidget {
  final RecVideoItemModel video;

  const _MoreButton({required this.video});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: Theme.of(context).colorScheme.outline,
        ),
        onSelected: (value) {
          final searchModel = video.toSearchVideoModel();
          if (value == 'queue') {
            final player = Get.find<PlayerController>();
            player.addToQueue(searchModel);
          } else if (value == 'fav') {
            final storage = Get.find<StorageService>();
            if (!storage.isLoggedIn) {
              Get.snackbar('提示', '请先登录',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            FavPanel.show(context, searchModel.id);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'queue',
            child: Row(
              children: [
                Icon(Icons.playlist_add, size: 20),
                SizedBox(width: 8),
                Text('添加到播放列表'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'fav',
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 20),
                SizedBox(width: 8),
                Text('收藏'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
