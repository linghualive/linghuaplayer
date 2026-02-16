import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/responsive/responsive_builder.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../music_discovery/music_discovery_controller.dart';
import '../../music_discovery/widgets/hot_playlist_card.dart';
import '../../music_discovery/widgets/mv_card.dart';
import '../../music_discovery/widgets/rank_song_card.dart';
import '../../music_discovery/widgets/section_header.dart';

/// Desktop-optimized music discovery page
class DesktopMusicDiscoveryPage extends GetView<MusicDiscoveryController> {
  const DesktopMusicDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.rankSongs.isEmpty &&
            controller.hotPlaylists.isEmpty &&
            controller.mvList.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAll(),
          child: CustomScrollView(
            slivers: [
              // Desktop search header
              SliverToBoxAdapter(
                child: _buildDesktopSearchHeader(context),
              ),

              // Hot Playlists
              if (controller.hotPlaylists.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: '热门歌单'),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.hotPlaylists),
                          child: const Text('查看更多'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildHotPlaylistsGrid(),
              ],

              // Rank Songs
              if (controller.rankSongs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => SectionHeader(
                              title: controller.rankTitle.value.isNotEmpty
                                  ? '音乐排行榜 · ${controller.rankTitle.value}'
                                  : '音乐排行榜',
                            )),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.musicRanking),
                          child: const Text('查看更多'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildRankSongsGrid(),
              ],

              // MV List
              if (controller.mvList.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: '音乐视频'),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.mvList),
                          child: const Text('查看更多'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildMVGrid(),
              ],

              // NetEase recommended playlists
              if (controller.neteaseRecommendPlaylists.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionHeader(title: '推荐歌单'),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.neteaseHotPlaylists),
                          child: const Text('查看更多'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildNeteasePlaylistsGrid(),
              ],

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopSearchHeader(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding =
            Breakpoints.getScreenPadding(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top + 16,
            padding.right,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.search),
                  child: Container(
                    height: 48,
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 24,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '搜索音乐、歌手、专辑',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ctrl+K',
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotPlaylistsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = Breakpoints.getGridColumns(
                  constraints.crossAxisExtent)
              .clamp(3, 6);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final playlist = controller.hotPlaylists[index];
                return HotPlaylistCard(
                  playlist: playlist,
                  onTap: () => Get.toNamed(
                    AppRoutes.audioPlaylistDetail,
                    arguments: playlist,
                  ),
                );
              },
              childCount: controller.hotPlaylists.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankSongsGrid() {
    return SliverToBoxAdapter(
      child: ResponsiveBuilder(
        compact: (context, constraints) => _buildRankSongsList(),
        medium: (context, constraints) =>
            _buildRankSongsColumns(2),
        expanded: (context, constraints) =>
            _buildRankSongsColumns(3),
        large: (context, constraints) =>
            _buildRankSongsColumns(3),
      ),
    );
  }

  Widget _buildRankSongsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: controller.rankSongs.map((song) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RankSongCard(
              song: song,
              onTap: () => controller.onRankSongTap(song),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankSongsColumns(int columnCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < columnCount; i++)
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: i < columnCount - 1 ? 16 : 0),
                child: Column(
                  children: controller.rankSongs
                      .where((r) =>
                          controller.rankSongs.indexOf(r) %
                              columnCount ==
                          i)
                      .map((song) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 16),
                            child: RankSongCard(
                              song: song,
                              onTap: () =>
                                  controller.onRankSongTap(song),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMVGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = Breakpoints.getGridColumns(
                  constraints.crossAxisExtent)
              .clamp(2, 4);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 16 / 13,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final mv = controller.mvList[index];
                return MvCard(
                  mv: mv,
                  onTap: () => controller.onMvTap(mv),
                );
              },
              childCount: controller.mvList.length.clamp(0, 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeteasePlaylistsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = Breakpoints.getGridColumns(
                  constraints.crossAxisExtent)
              .clamp(3, 6);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final playlist =
                    controller.neteaseRecommendPlaylists[index];
                return _NeteasePlaylistGridCard(
                  name: playlist.name,
                  coverUrl: playlist.coverUrl,
                  playCount: playlist.playCount,
                  onTap: () => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: playlist,
                  ),
                );
              },
              childCount:
                  controller.neteaseRecommendPlaylists.length,
            ),
          );
        },
      ),
    );
  }
}

class _NeteasePlaylistGridCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final int playCount;
  final VoidCallback? onTap;

  const _NeteasePlaylistGridCard({
    required this.name,
    required this.coverUrl,
    required this.playCount,
    this.onTap,
  });

  String _formatCount(int count) {
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
                  imageUrl: coverUrl,
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
                      _formatCount(playCount),
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
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
