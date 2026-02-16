import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../modules/home/home_controller.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/models/user/fav_resource_model.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/create_fav_dialog.dart';
import '../../shared/widgets/video_action_buttons.dart';
import 'playlist_controller.dart';
import 'widgets/playlist_config_sheet.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final outerTabCtrl = DefaultTabController.of(context);
          return AnimatedBuilder(
            animation: outerTabCtrl,
            builder: (context, _) {
              final isBilibili = outerTabCtrl.index == 0;
              return Scaffold(
                appBar: AppBar(
                  title: const Text('歌单'),
                  actions: isBilibili
                      ? [
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: '新建歌单',
                            onPressed: () => CreateFavDialog.show(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () =>
                                PlaylistConfigSheet.show(context),
                          ),
                        ]
                      : null,
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: '哔哩哔哩'),
                      Tab(text: '网易云'),
                    ],
                  ),
                ),
                body: const TabBarView(
                  children: [
                    _BilibiliPlaylistsView(),
                    _NeteasePlaylistsView(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildLoginPrompt(
  BuildContext context, {
  required IconData icon,
  required String label,
  Map<String, dynamic>? arguments,
}) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => Get.toNamed(AppRoutes.login, arguments: arguments),
          child: const Text('去登录'),
        ),
      ],
    ),
  );
}

// ── Bilibili View ───────────────────────────────────────

class _BilibiliPlaylistsView extends StatelessWidget {
  const _BilibiliPlaylistsView();

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
        return _buildLoginPrompt(
          context,
          icon: Icons.smart_display_outlined,
          label: '登录哔哩哔哩查看收藏夹',
        );
      }
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.visibleFolders.isEmpty) {
        return const Center(child: Text('暂无收藏夹'));
      }

      return DefaultTabController(
        length: controller.visibleFolders.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: controller.visibleFolders
                  .map((f) => Tab(text: f.title))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                children: controller.visibleFolders
                    .map((folder) => _FolderTab(
                          folderId: folder.id,
                          controller: controller,
                          formatPlay: _formatPlay,
                        ))
                    .toList(),
              ),
            ),
          ],
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadVideosForFolder(widget.folderId);
      });
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

// ── Netease View ────────────────────────────────────────

class _NeteasePlaylistsView extends StatelessWidget {
  const _NeteasePlaylistsView();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlaylistController>();
    final homeController = Get.find<HomeController>();

    return Obx(() {
      if (!homeController.isNeteaseLoggedIn.value) {
        return _buildLoginPrompt(
          context,
          icon: Icons.cloud_outlined,
          label: '登录网易云查看歌单',
          arguments: {'platform': 1},
        );
      }
      if (controller.neteaseIsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.neteasePlaylists.isEmpty) {
        return const Center(child: Text('暂无歌单'));
      }

      return DefaultTabController(
        length: controller.neteasePlaylists.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: controller.neteasePlaylists
                  .map((p) => Tab(text: p.name))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                children: controller.neteasePlaylists
                    .map((playlist) => _NeteasePlaylistTab(
                          playlistId: playlist.id,
                          controller: controller,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NeteasePlaylistTab extends StatefulWidget {
  final int playlistId;
  final PlaylistController controller;

  const _NeteasePlaylistTab({
    required this.playlistId,
    required this.controller,
  });

  @override
  State<_NeteasePlaylistTab> createState() => _NeteasePlaylistTabState();
}

class _NeteasePlaylistTabState extends State<_NeteasePlaylistTab> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.neteasePlaylistTracks[widget.playlistId] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadTracksForPlaylist(widget.playlistId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading =
          widget.controller.neteasePlaylistLoading[widget.playlistId] ?? false;
      final tracks = widget.controller
              .neteasePlaylistTracks[widget.playlistId] ??
          <SearchVideoModel>[];

      if (loading && tracks.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (tracks.isEmpty) {
        return const Center(child: Text('暂无歌曲'));
      }

      return ListView.builder(
        itemCount: tracks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return InkWell(
              onTap: () =>
                  widget.controller.playAllNetease(widget.playlistId),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '播放全部',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${tracks.length})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }
          final song = tracks[index - 1];
          return InkWell(
            onTap: () => widget.controller.playNeteaseSong(song),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CachedImage(
                    imageUrl: song.pic,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    song.duration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  VideoActionColumn(video: song),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
