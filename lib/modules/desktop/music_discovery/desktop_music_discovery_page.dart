import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/browse_models.dart';
import '../../../data/models/genre_categories.dart';
import '../../../data/repositories/netease_repository.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../music_discovery/music_discovery_controller.dart';
import '../../music_discovery/widgets/section_header.dart';

/// Desktop-optimized music discovery page
class DesktopMusicDiscoveryPage extends GetView<MusicDiscoveryController> {
  const DesktopMusicDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.curatedPlaylists.isEmpty) {
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

              // ── 1. 每日推荐（需登录）──
              if (controller.dailyRecommendSongs.isNotEmpty) ...[
                _buildSectionSliver('每日推荐'),
                SliverToBoxAdapter(
                  child: _buildHorizontalSongList(context),
                ),
              ],
              if (controller.dailyRecommendPlaylists.isNotEmpty) ...[
                _buildSectionSliver('每日推荐歌单'),
                _buildNeteasePlaylistsGrid(
                  controller.dailyRecommendPlaylists,
                ),
              ],

              // ── 2. 精选歌单推荐 ──
              if (controller.curatedPlaylists.isNotEmpty) ...[
                _buildSectionSliverWithAction(
                  '精选歌单推荐',
                  () => Get.toNamed(AppRoutes.neteaseHotPlaylists),
                ),
                _buildUnifiedPlaylistsGrid(),
              ],

              // ── 4. 多源排行榜 ──
              if (controller.neteaseToplistPreview.isNotEmpty ||
                  controller.qqMusicToplistPreview.isNotEmpty) ...[
                _buildSectionSliver('多源排行榜'),
                if (controller.neteaseToplistPreview.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSourceLabel('网易云', context),
                  ),
                  _buildNeteaseToplistGrid(),
                ],
                if (controller.qqMusicToplistPreview.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSourceLabel('QQ音乐', context),
                  ),
                  _buildQqToplistGrid(),
                ],
              ],

              // ── 5. 风格分类歌单 ──
              _buildGenreSliver(context),

              // ── 6. 发现音乐 ──
              _buildDiscoverSliver(context),

              // ── 7. 热门歌手推荐 ──
              _buildSingerSliver(context),

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

  // ── Section header slivers ──

  SliverToBoxAdapter _buildSectionSliver(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SectionHeader(title: title),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionSliverWithAction(
      String title, VoidCallback onViewAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(title: title),
            TextButton(
              onPressed: onViewAll,
              child: const Text('查看更多'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceLabel(String label, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Song lists ──

  Widget _buildHorizontalSongList(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: controller.dailyRecommendSongs.length,
        itemBuilder: (context, index) {
          final song = controller.dailyRecommendSongs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => controller.onDailyRecommendSongTap(song),
              child: SizedBox(
                width: 220,
                child: Row(
                  children: [
                    CachedImage(
                      imageUrl: song.pic,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 2),
                          Text(
                            song.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Playlist grids ──

  Widget _buildNeteasePlaylistsGrid(
      List<NeteasePlaylistBrief> playlists) {
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
                final playlist = playlists[index];
                return _DesktopPlaylistCard(
                  name: playlist.name,
                  coverUrl: playlist.coverUrl,
                  playCount: playlist.playCount,
                  onTap: () => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: playlist,
                  ),
                );
              },
              childCount: playlists.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedPlaylistsGrid() {
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
                final playlist = controller.curatedPlaylists[index];
                return _DesktopUnifiedPlaylistCard(
                  playlist: playlist,
                  onTap: () => controller.navigateToPlaylist(playlist),
                );
              },
              childCount: controller.curatedPlaylists.length,
            ),
          );
        },
      ),
    );
  }

  // ── Toplist grids ──

  Widget _buildNeteaseToplistGrid() {
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
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final toplist = controller.neteaseToplistPreview[index];
                return _ToplistGridCard(
                  name: toplist.name,
                  coverUrl: toplist.coverUrl,
                  onTap: () => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: toplist.id,
                  ),
                );
              },
              childCount: controller.neteaseToplistPreview.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQqToplistGrid() {
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
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final toplist = controller.qqMusicToplistPreview[index];
                return _ToplistGridCard(
                  name: toplist.name,
                  coverUrl: toplist.coverUrl,
                  onTap: () => Get.toNamed(
                    AppRoutes.qqMusicPlaylistDetail,
                    arguments: {
                      'disstid': toplist.id,
                      'title': toplist.name,
                    },
                  ),
                );
              },
              childCount: controller.qqMusicToplistPreview.length,
            ),
          );
        },
      ),
    );
  }

  // ── Genre section ──

  SliverToBoxAdapter _buildGenreSliver(BuildContext context) {
    final theme = Theme.of(context);
    final allTags = <String>[];
    for (final category in kGenreCategories) {
      allTags.addAll(category.tags);
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: '风格分类歌单'),
                TextButton(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.neteaseHotPlaylists),
                  child: const Text('查看更多'),
                ),
              ],
            ),
          ),
          // Genre tag selector
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: allTags.length,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Obx(() {
                    final isSelected =
                        controller.selectedGenre.value == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.onGenreChanged(tag),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Genre playlists
          Obx(() {
            if (controller.isLoadingGenre.value) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.genrePlaylists.isEmpty) {
              return const SizedBox(
                height: 60,
                child: Center(child: Text('暂无歌单')),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = Breakpoints.getGridColumns(
                          constraints.maxWidth)
                      .clamp(3, 6);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.genrePlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist =
                          controller.genrePlaylists[index];
                      return _DesktopPlaylistCard(
                        name: playlist.name,
                        coverUrl: playlist.coverUrl,
                        playCount: playlist.playCount,
                        onTap: () => Get.toNamed(
                          AppRoutes.neteasePlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Discover section ──

  SliverToBoxAdapter _buildDiscoverSliver(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SectionHeader(title: '发现音乐'),
          ),
          // Category selector
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount:
                  MusicDiscoveryController.discoverCategories.length,
              itemBuilder: (context, index) {
                final cat =
                    MusicDiscoveryController.discoverCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Obx(() {
                    final isSelected =
                        controller.selectedDiscoverCategory.value ==
                            cat['keyword'];
                    return ChoiceChip(
                      label: Text(cat['label']!),
                      selected: isSelected,
                      onSelected: (_) => controller
                          .onDiscoverCategoryChanged(cat['keyword']!),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Discover playlists
          Obx(() {
            if (controller.isLoadingDiscover.value) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.discoverPlaylists.isEmpty) {
              return const SizedBox(
                height: 60,
                child: Center(child: Text('暂无歌单')),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = Breakpoints.getGridColumns(
                          constraints.maxWidth)
                      .clamp(3, 6);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.discoverPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist =
                          controller.discoverPlaylists[index];
                      return _DesktopPlaylistCard(
                        name: playlist.name,
                        coverUrl: playlist.coverUrl,
                        playCount: playlist.playCount,
                        onTap: () => Get.toNamed(
                          AppRoutes.neteasePlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Singer section ──

  SliverToBoxAdapter _buildSingerSliver(BuildContext context) {
    final theme = Theme.of(context);
    const areaOptions = [
      (200, '华语'),
      (2, '港台'),
      (5, '欧美'),
      (4, '日本'),
      (3, '韩国'),
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SectionHeader(title: '热门歌手推荐'),
          ),
          // Area selector
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: areaOptions.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Obx(() {
                    final isSelected =
                        controller.selectedSingerArea.value ==
                            option.$1;
                    return ChoiceChip(
                      label: Text(option.$2),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.onSingerAreaChanged(option.$1),
                      labelStyle:
                          theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Singer grid
          Obx(() {
            if (controller.isLoadingSingers.value) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.hotSingers.isEmpty) {
              return const SizedBox(
                height: 60,
                child: Center(child: Text('暂无歌手')),
              );
            }
            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: controller.hotSingers.length,
                itemBuilder: (context, index) {
                  final singer = controller.hotSingers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: GestureDetector(
                      onTap: () => controller.onSingerTap(singer),
                      child: SizedBox(
                        width: 80,
                        child: Column(
                          children: [
                            CachedImage(
                              imageUrl: singer.picUrl,
                              width: 72,
                              height: 72,
                              borderRadius:
                                  BorderRadius.circular(36),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              singer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Desktop playlist card ──

class _DesktopPlaylistCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final int playCount;
  final VoidCallback? onTap;

  const _DesktopPlaylistCard({
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

// ── Desktop unified playlist card ──

class _DesktopUnifiedPlaylistCard extends StatelessWidget {
  final PlaylistBrief playlist;
  final VoidCallback? onTap;

  const _DesktopUnifiedPlaylistCard({
    required this.playlist,
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
                  imageUrl: playlist.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(8),
                ),
                if (playlist.playCount > 0)
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
                        _formatCount(playlist.playCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: playlist.sourceId == 'qqmusic'
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      playlist.sourceId == 'qqmusic' ? 'QQ' : '网易',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
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

// ── Toplist grid card ──

class _ToplistGridCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final VoidCallback? onTap;

  const _ToplistGridCard({
    required this.name,
    required this.coverUrl,
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
            child: CachedImage(
              imageUrl: coverUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
