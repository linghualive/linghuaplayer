import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/duration_formatter.dart';
import '../../shared/widgets/fav_panel.dart';
import '../player/player_controller.dart';
import 'mv_list_controller.dart';

class MvListPage extends StatelessWidget {
  const MvListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MvListController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('音乐视频')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.mvList.isEmpty) {
          return const Center(child: Text('暂无数据'));
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
            onRefresh: controller.loadMvList,
            child: ListView.builder(
              itemCount: controller.mvList.length +
                  (controller.hasMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.mvList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final mv = controller.mvList[index];
                return InkWell(
                  onTap: () => controller.onMvTap(mv),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 16:9 thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: mv.cover,
                                width: 160,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 160,
                                  height: 90,
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 160,
                                  height: 90,
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.music_video),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    DurationFormatter.format(mv.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mv.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  mv.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.playlist_add, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          final playerCtrl =
                                              Get.find<PlayerController>();
                                          playerCtrl.addToQueue(
                                              mv.toSearchVideoModel());
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.favorite_border,
                                            size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints(),
                                        visualDensity:
                                            VisualDensity.compact,
                                        tooltip: '收藏到歌单',
                                        onPressed: () => FavPanel.show(
                                            context,
                                            mv.toSearchVideoModel()),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
