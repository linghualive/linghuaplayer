import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/duration_formatter.dart';
import '../../shared/widgets/animated_list_item.dart';
import '../../shared/widgets/fav_panel.dart';
import '../player/player_controller.dart';
import 'audio_playlist_detail_controller.dart';

class AudioPlaylistDetailPage extends StatelessWidget {
  const AudioPlaylistDetailPage({super.key});

  String _formatCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioPlaylistDetailController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(controller.title)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: CustomScrollView(
            slivers: [
              // Playlist header
              if (controller.detail.value != null)
                SliverToBoxAdapter(
                  child: _buildHeader(context, controller, theme),
                ),

              // Play all + Add all buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: controller.playAll,
                        icon: const Icon(Icons.play_arrow),
                        label: Text('播放全部 (${controller.songs.length})'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: controller.addAllToQueue,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('全部添加'),
                      ),
                    ],
                  ),
                ),
              ),

              // Song list
              if (controller.songs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('暂无歌曲')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = controller.songs[index];
                      return AnimatedListItem(
                        index: index,
                        child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: song.cover,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 48,
                              height: 48,
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              child: Icon(Icons.music_note_rounded, size: 20,
                                  color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          song.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline.withValues(alpha: 0.8),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.playlist_add_rounded, size: 20,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () {
                                final playerCtrl =
                                    Get.find<PlayerController>();
                                playerCtrl
                                    .addToQueue(song.toSearchVideoModel());
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_border_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              tooltip: '收藏到歌单',
                              onPressed: () => FavPanel.show(
                                  context, song.toSearchVideoModel()),
                            ),
                            Text(
                              DurationFormatter.format(song.duration),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => controller.playSong(song),
                      ),
                      );
                    },
                    childCount: controller.songs.length,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context,
      AudioPlaylistDetailController controller, ThemeData theme) {
    final detail = controller.detail.value!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: detail.cover,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 120,
                  height: 120,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Icon(Icons.queue_music_rounded, size: 36,
                      color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  detail.author,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatCount(detail.playCount)} 播放 · ${detail.songCount} 首',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (detail.intro.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail.intro,
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
}
