import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/cached_image.dart';
import 'netease_artist_detail_controller.dart';

class NeteaseArtistDetailPage extends StatelessWidget {
  const NeteaseArtistDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NeteaseArtistDetailController>();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                controller.detail.value?.name ?? controller.artistName,
              )),
          bottom: const TabBar(
            tabs: [
              Tab(text: '热门歌曲'),
              Tab(text: '专辑'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _buildHotSongsTab(context, controller, theme),
              _buildAlbumsTab(context, controller, theme),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHotSongsTab(BuildContext context,
      NeteaseArtistDetailController controller, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: controller.reload,
      child: CustomScrollView(
        slivers: [
          // Artist header
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
                    label: Text(
                        '播放全部 (${controller.detail.value?.hotSongs.length ?? 0})'),
                  ),
                ],
              ),
            ),
          ),

          // Hot songs list
          if (controller.detail.value?.hotSongs.isEmpty ?? true)
            const SliverFillRemaining(
              child: Center(child: Text('暂无歌曲')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = controller.detail.value!.hotSongs[index];
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
                      song.description.isNotEmpty
                          ? song.description
                          : song.author,
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
                childCount:
                    controller.detail.value?.hotSongs.length ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumsTab(BuildContext context,
      NeteaseArtistDetailController controller, ThemeData theme) {
    if (controller.albums.isEmpty) {
      return const Center(child: Text('暂无专辑'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: controller.albums.length,
      itemBuilder: (context, index) {
        final album = controller.albums[index];
        return _AlbumGridCard(
          album: album,
          onTap: () => Get.toNamed(
            AppRoutes.neteaseAlbumDetail,
            arguments: album,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context,
      NeteaseArtistDetailController controller, ThemeData theme) {
    final detail = controller.detail.value!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: detail.picUrl.isNotEmpty
                ? CachedNetworkImageProvider(detail.picUrl)
                : null,
            child: detail.picUrl.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
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
                ),
                const SizedBox(height: 4),
                Text(
                  '${detail.musicSize} 首歌曲 · ${detail.albumSize} 张专辑',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (detail.briefDesc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail.briefDesc,
                    maxLines: 3,
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

class _AlbumGridCard extends StatelessWidget {
  final NeteaseAlbumBrief album;
  final VoidCallback? onTap;

  const _AlbumGridCard({required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CachedImage(
              imageUrl: album.picUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            album.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
