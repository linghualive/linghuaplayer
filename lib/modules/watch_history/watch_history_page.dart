import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/video_action_buttons.dart';
import 'watch_history_controller.dart';

class WatchHistoryPage extends StatelessWidget {
  const WatchHistoryPage({super.key});

  String _relativeTime(int playedAtMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - playedAtMs) ~/ 1000;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return '${diff ~/ 60} 分钟前';
    if (diff < 86400) return '${diff ~/ 3600} 小时前';
    if (diff < 2592000) return '${diff ~/ 86400} 天前';
    return '${diff ~/ 2592000} 个月前';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WatchHistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('全部清空'),
                  content: const Text('确定要清空全部播放历史吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.clearAll();
                      },
                      child: const Text('清空'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.videos.isEmpty) {
          return const Center(child: Text('暂无播放历史'));
        }
        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView.builder(
            itemCount: controller.videos.length,
            itemBuilder: (context, index) {
              final video = controller.videos[index];
              final playedAt = controller.playedAtList[index];
              return Dismissible(
                key: ValueKey('${video.uniqueId}_$playedAt'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => controller.deleteItem(index),
                child: InkWell(
                  onTap: () => controller.playVideo(video),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(minHeight: 100),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const SizedBox(height: 4),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: video.isNetease
                                            ? Colors.red.withValues(
                                                alpha: 0.1)
                                            : Colors.blue.withValues(
                                                alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        video.isNetease ? '网易云' : 'B站',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: video.isNetease
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _relativeTime(playedAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        VideoActionColumn(
                          video: video,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
