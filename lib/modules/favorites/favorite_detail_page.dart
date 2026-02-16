import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/video_action_buttons.dart';
import 'favorite_detail_controller.dart';

class FavoriteDetailPage extends StatelessWidget {
  const FavoriteDetailPage({super.key});

  String _formatPlay(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoriteDetailController>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.videos.isEmpty) {
          return const Center(child: Text('暂无视频'));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: controller.loadVideos,
            child: ListView.builder(
              itemCount: controller.videos.length + 1 +
                  (controller.hasMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: controller.playAll,
                            icon: const Icon(Icons.play_circle_filled,
                                size: 20),
                            label: Text(
                                '播放全部 (${controller.videos.length})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: controller.addAllToQueue,
                          icon: const Icon(Icons.playlist_add, size: 20),
                          label: const Text('全部添加'),
                        ),
                      ],
                    ),
                  );
                }
                final videoIndex = index - 1;
                if (videoIndex >= controller.videos.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final video = controller.videos[videoIndex];
                return InkWell(
                  onTap: () => controller.playVideo(video),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedImage(
                          imageUrl: video.pic,
                          width: 160,
                          height: 100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  video.author,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.play_arrow,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                    const SizedBox(width: 2),
                                    Text(
                                      _formatPlay(video.play),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.comment_outlined,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                    const SizedBox(width: 2),
                                    Text(
                                      _formatPlay(video.danmaku),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      video.durationStr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        VideoActionColumn(
                          video: video.toSearchVideoModel(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
