import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/responsive/responsive_builder.dart';
import '../../../shared/responsive/breakpoints.dart';
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
        if (controller.isLoading.value) {
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
                          onPressed: () => Get.toNamed(AppRoutes.neteaseHotPlaylists),
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
                        SectionHeader(title: controller.rankTitle.value.isNotEmpty ? controller.rankTitle.value : '排行榜'),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.musicRanking),
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
                    child: const SectionHeader(
                      title: '推荐MV',
                    ),
                  ),
                ),
                _buildMVGrid(),
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
        final padding = Breakpoints.getScreenPadding(constraints.maxWidth);

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
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ctrl+K',
                            style: theme.textTheme.labelSmall?.copyWith(
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
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = Breakpoints.getScreenPadding(constraints.maxWidth);
          final columns = Breakpoints.getGridColumns(constraints.maxWidth);
          final itemsToShow = columns * 2; // Show 2 rows

          return SizedBox(
            height: 280, // Fixed height for 2 rows
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: padding.left),
              itemCount: controller.hotPlaylists.length.clamp(0, itemsToShow),
              itemBuilder: (context, index) {
                final playlist = controller.hotPlaylists[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < itemsToShow - 1 ? 16 : padding.right,
                  ),
                  child: SizedBox(
                    width: 200,
                    child: HotPlaylistCard(playlist: playlist),
                  ),
                );
              },
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
        medium: (context, constraints) => _buildRankSongsGrid2Columns(),
        expanded: (context, constraints) => _buildRankSongsGrid3Columns(),
        large: (context, constraints) => _buildRankSongsGrid3Columns(),
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
            child: RankSongCard(song: song),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankSongsGrid2Columns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: controller.rankSongs
                  .where((r) => controller.rankSongs.indexOf(r) % 2 == 0)
                  .map((song) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RankSongCard(song: song),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: controller.rankSongs
                  .where((r) => controller.rankSongs.indexOf(r) % 2 == 1)
                  .map((song) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RankSongCard(song: song),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankSongsGrid3Columns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 16 : 0),
                child: Column(
                  children: controller.rankSongs
                      .where((r) => controller.rankSongs.indexOf(r) % 3 == i)
                      .map((song) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RankSongCard(song: song),
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
          final columns = Breakpoints.getGridColumns(constraints.crossAxisExtent);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns.clamp(2, 4), // MV cards work better with fewer columns
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 16 / 10, // Video aspect ratio
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final mv = controller.mvList[index];
                return MvCard(mv: mv);
              },
              childCount: controller.mvList.length.clamp(0, 8), // Show max 8 MVs
            ),
          );
        },
      ),
    );
  }
}