import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'netease_album_detail_controller.dart';

class NeteaseAlbumDetailPage extends StatelessWidget {
  const NeteaseAlbumDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NeteaseAlbumDetailController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.detail.value?.name ?? controller.albumName,
            )),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: CustomScrollView(
            slivers: [
              // Album header
              if (controller.detail.value != null)
                SliverToBoxAdapter(
                  child: _buildHeader(context, controller, theme),
                ),

              // Play all button
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: controller.playAll,
                        icon: const Icon(Icons.play_arrow),
                        label:
                            Text('播放全部 (${controller.tracks.length})'),
                      ),
                    ],
                  ),
                ),
              ),

              // Song list
              if (controller.tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('暂无歌曲')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = controller.tracks[index];
                      return ListTile(
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
                      );
                    },
                    childCount: controller.tracks.length,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context,
      NeteaseAlbumDetailController controller, ThemeData theme) {
    final detail = controller.detail.value!;
    final date = detail.publishTime > 0
        ? DateTime.fromMillisecondsSinceEpoch(detail.publishTime)
        : null;
    final dateStr = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: detail.picUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: detail.picUrl,
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
                      child: const Icon(Icons.album, size: 40),
                    ),
                  )
                : Container(
                    width: 120,
                    height: 120,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.album, size: 40),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  detail.artistName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                if (detail.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail.description,
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
