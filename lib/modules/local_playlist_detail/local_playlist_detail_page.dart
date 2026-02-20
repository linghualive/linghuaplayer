import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'local_playlist_detail_controller.dart';

class LocalPlaylistDetailPage extends StatelessWidget {
  const LocalPlaylistDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocalPlaylistDetailController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.playlist.value?.name ?? '')),
        actions: [
          Obx(() {
            final p = controller.playlist.value;
            if (p == null || p.remoteId == null) return const SizedBox.shrink();
            return IconButton(
              icon: controller.isRefreshing.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '从远程刷新',
              onPressed: controller.isRefreshing.value
                  ? null
                  : controller.refreshFromRemote,
            );
          }),
        ],
      ),
      body: Obx(() {
        final p = controller.playlist.value;
        if (p == null) {
          return const Center(child: Text('歌单不存在'));
        }

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, controller, theme, p),
            ),

            // Action bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: controller.playAll,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('播放全部 (${controller.tracks.length})'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: controller.addAllToQueue,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('加入队列'),
                    ),
                  ],
                ),
              ),
            ),

            // Track list
            if (controller.tracks.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('暂无歌曲')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = controller.tracks[index];
                    return Dismissible(
                      key: ValueKey(song.uniqueId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.error,
                        child: Icon(Icons.delete,
                            color: theme.colorScheme.onError),
                      ),
                      onDismissed: (_) => controller.removeTrack(index),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: song.pic.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: song.pic,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 48,
                                    height: 48,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.music_note,
                                        size: 20),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child:
                                      const Icon(Icons.music_note, size: 20),
                                ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: theme.colorScheme.outline),
                        ),
                        trailing: Text(
                          song.duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        onTap: () => controller.playSong(song),
                      ),
                    );
                  },
                  childCount: controller.tracks.length,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LocalPlaylistDetailController controller,
    ThemeData theme,
    dynamic p,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: p.coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: p.coverUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.queue_music, size: 40),
                    ),
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.queue_music, size: 40),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Source badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _sourceColor(p.sourceTag, theme).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _sourceLabel(p.sourceTag),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _sourceColor(p.sourceTag, theme),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.trackCount} 首',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _sourceLabel(String sourceTag) {
    switch (sourceTag) {
      case 'bilibili':
        return 'Bilibili';
      case 'netease':
        return '网易云';
      case 'qqmusic':
        return 'QQ音乐';
      case 'local':
        return '本地';
      default:
        return sourceTag;
    }
  }

  static Color _sourceColor(String sourceTag, ThemeData theme) {
    switch (sourceTag) {
      case 'bilibili':
        return const Color(0xFFFB7299);
      case 'netease':
        return const Color(0xFFE60026);
      case 'qqmusic':
        return const Color(0xFF31C27C);
      case 'local':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }
}
