import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/cached_image.dart';
import 'netease_hot_playlists_controller.dart';

class NeteaseHotPlaylistsPage extends StatelessWidget {
  const NeteaseHotPlaylistsPage({super.key});

  // Default hot categories to show as chips
  static const _defaultCategories = [
    '全部',
    '华语',
    '欧美',
    '日语',
    '韩语',
    '摇滚',
    '电子',
    '流行',
    'ACG',
    '说唱',
    '民谣',
    '古典',
    '轻音乐',
  ];

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NeteaseHotPlaylistsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('热门歌单'),
        actions: [
          Obx(() => PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: controller.switchOrder,
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(
                    value: 'hot',
                    checked: controller.sortOrder.value == 'hot',
                    child: const Text('热门'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'new',
                    checked: controller.sortOrder.value == 'new',
                    child: const Text('最新'),
                  ),
                ],
              )),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _defaultCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _defaultCategories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected:
                            controller.selectedCategory.value == cat,
                        onSelected: (_) =>
                            controller.switchCategory(cat),
                      ),
                    );
                  },
                )),
          ),

          // Playlist grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.playlists.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.playlists.isEmpty) {
                return const Center(child: Text('暂无歌单'));
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                    controller.loadMore();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: controller.reload,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = Breakpoints.getGridColumns(
                              constraints.maxWidth)
                          .clamp(3, 6);

                      return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.playlists.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.playlists.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final playlist = controller.playlists[index];
                      return _PlaylistGridCard(
                        playlist: playlist,
                        formatPlayCount: _formatPlayCount,
                        onTap: () => Get.toNamed(
                          AppRoutes.neteasePlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PlaylistGridCard extends StatelessWidget {
  final NeteasePlaylistBrief playlist;
  final VoidCallback? onTap;
  final String Function(int) formatPlayCount;

  const _PlaylistGridCard({
    required this.playlist,
    required this.formatPlayCount,
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
          Expanded(
            child: Stack(
              children: [
                CachedImage(
                  imageUrl: playlist.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(8),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatPlayCount(playlist.playCount),
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
          const SizedBox(height: 4),
          Text(
            playlist.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
