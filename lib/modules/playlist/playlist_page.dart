import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/home/home_controller.dart';
import '../../data/models/user/fav_resource_model.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/create_fav_dialog.dart';
import '../../shared/widgets/video_action_buttons.dart';
import 'playlist_controller.dart';
import 'widgets/playlist_config_sheet.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  String _formatPlay(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlaylistController>();
    final homeController = Get.find<HomeController>();

    return Obx(() {
      if (!homeController.isLoggedIn.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('歌单')),
          body: const Center(child: Text('请先登录哔哩哔哩')),
        );
      }
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('歌单')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.visibleFolders.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('歌单'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '新建歌单',
                onPressed: () => CreateFavDialog.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => PlaylistConfigSheet.show(context),
              ),
            ],
          ),
          body: const Center(child: Text('暂无收藏夹')),
        );
      }

      return DefaultTabController(
        length: controller.visibleFolders.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('歌单'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '新建歌单',
                onPressed: () => CreateFavDialog.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => PlaylistConfigSheet.show(context),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: controller.visibleFolders
                  .map((f) => Tab(text: f.title))
                  .toList(),
            ),
          ),
          body: TabBarView(
            children: controller.visibleFolders
                .map((folder) => _FolderTab(
                      folderId: folder.id,
                      controller: controller,
                      formatPlay: _formatPlay,
                    ))
                .toList(),
          ),
        ),
      );
    });
  }
}

class _FolderTab extends StatefulWidget {
  final int folderId;
  final PlaylistController controller;
  final String Function(int) formatPlay;

  const _FolderTab({
    required this.folderId,
    required this.controller,
    required this.formatPlay,
  });

  @override
  State<_FolderTab> createState() => _FolderTabState();
}

class _FolderTabState extends State<_FolderTab> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.tabVideos[widget.folderId] == null) {
      widget.controller.loadVideosForFolder(widget.folderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = widget.controller.tabLoading[widget.folderId] ?? false;
      final videos =
          widget.controller.tabVideos[widget.folderId] ?? <FavResourceModel>[];
      final hasMore = widget.controller.tabHasMore[widget.folderId] ?? false;

      if (loading && videos.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (videos.isEmpty) {
        return const Center(child: Text('暂无视频'));
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            widget.controller.loadMoreForFolder(widget.folderId);
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () =>
              widget.controller.loadVideosForFolder(widget.folderId),
          child: ListView.builder(
            itemCount: videos.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= videos.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final video = videos[index];
              return InkWell(
                onTap: () => widget.controller.playVideo(video),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
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
                                  widget.formatPlay(video.play),
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
    });
  }
}
