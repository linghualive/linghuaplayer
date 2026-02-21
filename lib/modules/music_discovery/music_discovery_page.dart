import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/browse_models.dart';
import '../../data/models/genre_categories.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/cached_image.dart';
import 'music_discovery_controller.dart';
import 'widgets/section_header.dart';

class MusicDiscoveryPage extends StatelessWidget {
  const MusicDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicDiscoveryController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.search),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(19),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索音乐',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.curatedPlaylists.isEmpty) {
          return _buildSkeleton(theme);
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.only(top: 4),
            children: [
              // ── 1. 每日推荐歌曲 ──
              if (controller.dailyRecommendSongs.isNotEmpty) ...[
                const SectionHeader(title: '每日推荐'),
                const SizedBox(height: 4),
                _buildDailySongList(
                  songs: controller.dailyRecommendSongs,
                  onTap: controller.onDailyRecommendSongTap,
                  theme: theme,
                ),
                const SizedBox(height: 16),
              ],

              // ── 2. 每日推荐歌单 ──
              if (controller.dailyRecommendPlaylists.isNotEmpty) ...[
                const SectionHeader(title: '每日推荐歌单'),
                const SizedBox(height: 4),
                _buildPlaylistScroll(
                  playlists: controller.dailyRecommendPlaylists
                      .map((p) => PlaylistBrief(
                            id: p.id.toString(),
                            sourceId: 'netease',
                            name: p.name,
                            coverUrl: p.coverUrl,
                            playCount: p.playCount,
                          ))
                      .toList(),
                  onTap: (p) => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: NeteasePlaylistBrief(
                      id: int.tryParse(p.id) ?? 0,
                      name: p.name,
                      coverUrl: p.coverUrl,
                      playCount: p.playCount,
                    ),
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 16),
              ],

              // ── 3. 精选歌单推荐 ──
              if (controller.curatedPlaylists.isNotEmpty) ...[
                SectionHeader(
                  title: '精选歌单推荐',
                  onViewAll: () =>
                      Get.toNamed(AppRoutes.neteaseHotPlaylists),
                ),
                const SizedBox(height: 4),
                _buildPlaylistScroll(
                  playlists: controller.curatedPlaylists,
                  onTap: controller.navigateToPlaylist,
                  theme: theme,
                  showSource: true,
                ),
                const SizedBox(height: 16),
              ],

              // ── 4. 风格分类歌单 ──
              _buildGenreSection(controller, theme),
              const SizedBox(height: 16),

              // ── 5. 发现音乐 ──
              _buildDiscoverSection(controller, theme),
              const SizedBox(height: 16),

              // ── 7. 多源排行榜 ──
              if (controller.neteaseToplistPreview.isNotEmpty ||
                  controller.qqMusicToplistPreview.isNotEmpty) ...[
                const SectionHeader(title: '排行榜'),
                const SizedBox(height: 4),
                _buildToplistSection(controller, theme),
                const SizedBox(height: 16),
              ],

              // ── 8. 热门歌手推荐 ──
              _buildSingerSection(controller, theme),

              // 底部留白
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  // ── 骨架屏 ──

  Widget _buildSkeleton(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Section title
          Container(
            height: 16,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Playlist row
          SizedBox(
            height: 180,
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Another section
          Container(
            height: 16,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Toplist row
          SizedBox(
            height: 120,
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 每日推荐歌曲（带序号的卡片式列表）──

  Widget _buildDailySongList({
    required List<SearchVideoModel> songs,
    required void Function(SearchVideoModel) onTap,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onTap(song),
              child: SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          CachedImage(
                            imageUrl: song.pic,
                            width: 130,
                            height: double.infinity,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // Play icon overlay
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 20,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      song.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
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

  // ── 歌单横向滚动 ──

  Widget _buildPlaylistScroll({
    required List<PlaylistBrief> playlists,
    required void Function(PlaylistBrief) onTap,
    required ThemeData theme,
    bool showSource = false,
  }) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _PlaylistCard(
              playlist: playlist,
              onTap: () => onTap(playlist),
              showSource: showSource,
            ),
          );
        },
      ),
    );
  }

  // ── 风格分类歌单板块 ──

  Widget _buildGenreSection(
      MusicDiscoveryController controller, ThemeData theme) {
    final allTags = <String>[];
    for (final category in kGenreCategories) {
      allTags.addAll(category.tags);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '风格分类歌单',
          onViewAll: () => Get.toNamed(AppRoutes.neteaseHotPlaylists),
        ),
        const SizedBox(height: 4),
        // Genre tag selector
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Obx(() {
                  final isSelected = controller.selectedGenre.value == tag;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => controller.onGenreChanged(tag),
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
        const SizedBox(height: 8),
        // Genre playlists
        Obx(() {
          if (controller.isLoadingGenre.value) {
            return SizedBox(
              height: 190,
              child: Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceContainerHighest,
                highlightColor: theme.colorScheme.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (controller.genrePlaylists.isEmpty) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('暂无歌单')),
            );
          }
          return _buildPlaylistScroll(
            playlists: controller.genrePlaylists
                .map((p) => PlaylistBrief(
                      id: p.id.toString(),
                      sourceId: 'netease',
                      name: p.name,
                      coverUrl: p.coverUrl,
                      playCount: p.playCount,
                    ))
                .toList(),
            onTap: (p) => Get.toNamed(
              AppRoutes.neteasePlaylistDetail,
              arguments: NeteasePlaylistBrief(
                id: int.tryParse(p.id) ?? 0,
                name: p.name,
                coverUrl: p.coverUrl,
                playCount: p.playCount,
              ),
            ),
            theme: theme,
          );
        }),
      ],
    );
  }

  // ── 发现音乐板块 ──

  Widget _buildDiscoverSection(
      MusicDiscoveryController controller, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '发现音乐'),
        const SizedBox(height: 4),
        // Category selector
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: MusicDiscoveryController.discoverCategories.length,
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
        const SizedBox(height: 8),
        // Discover playlists
        Obx(() {
          if (controller.isLoadingDiscover.value) {
            return SizedBox(
              height: 190,
              child: Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceContainerHighest,
                highlightColor: theme.colorScheme.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (controller.discoverPlaylists.isEmpty) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('暂无歌单')),
            );
          }
          return _buildPlaylistScroll(
            playlists: controller.discoverPlaylists
                .map((p) => PlaylistBrief(
                      id: p.id.toString(),
                      sourceId: 'netease',
                      name: p.name,
                      coverUrl: p.coverUrl,
                      playCount: p.playCount,
                    ))
                .toList(),
            onTap: (p) => Get.toNamed(
              AppRoutes.neteasePlaylistDetail,
              arguments: NeteasePlaylistBrief(
                id: int.tryParse(p.id) ?? 0,
                name: p.name,
                coverUrl: p.coverUrl,
                playCount: p.playCount,
              ),
            ),
            theme: theme,
          );
        }),
      ],
    );
  }

  // ── 排行榜板块（合并显示）──

  Widget _buildToplistSection(
      MusicDiscoveryController controller, ThemeData theme) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Netease toplists
          ...controller.neteaseToplistPreview.map((toplist) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ToplistCard(
                  name: toplist.name,
                  coverUrl: toplist.coverUrl,
                  sourceLabel: '网易云',
                  trackPreviews: toplist.trackPreviews,
                  onTap: () => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: toplist.id,
                  ),
                ),
              )),
          // QQ Music toplists
          ...controller.qqMusicToplistPreview.map((toplist) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ToplistCard(
                  name: toplist.name,
                  coverUrl: toplist.coverUrl,
                  sourceLabel: 'QQ',
                  trackPreviews: toplist.trackPreviews,
                  onTap: () => Get.toNamed(
                    AppRoutes.qqMusicPlaylistDetail,
                    arguments: {
                      'disstid': toplist.id,
                      'title': toplist.name,
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── 热门歌手推荐板块 ──

  Widget _buildSingerSection(
      MusicDiscoveryController controller, ThemeData theme) {
    const areaOptions = [
      (200, '华语'),
      (2, '港台'),
      (5, '欧美'),
      (4, '日本'),
      (3, '韩国'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '热门歌手'),
        const SizedBox(height: 4),
        // Area selector
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: areaOptions.map((option) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Obx(() {
                  final isSelected =
                      controller.selectedSingerArea.value == option.$1;
                  return ChoiceChip(
                    label: Text(option.$2),
                    selected: isSelected,
                    onSelected: (_) =>
                        controller.onSingerAreaChanged(option.$1),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
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
        const SizedBox(height: 8),
        // Singer scroll
        Obx(() {
          if (controller.isLoadingSingers.value) {
            return SizedBox(
              height: 110,
              child: Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceContainerHighest,
                highlightColor: theme.colorScheme.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.hotSingers.length,
              itemBuilder: (context, index) {
                final singer = controller.hotSingers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => controller.onSingerTap(singer),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          CachedImage(
                            imageUrl: singer.picUrl,
                            width: 68,
                            height: 68,
                            borderRadius: BorderRadius.circular(34),
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
    );
  }
}

// ── 歌单卡片 ──

class _PlaylistCard extends StatelessWidget {
  final PlaylistBrief playlist;
  final VoidCallback? onTap;
  final bool showSource;

  const _PlaylistCard({
    required this.playlist,
    this.onTap,
    this.showSource = false,
  });

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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  CachedImage(
                    imageUrl: playlist.coverUrl,
                    width: 130,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // Play count badge
                  if (playlist.playCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 1),
                            Text(
                              _formatPlayCount(playlist.playCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Source badge
                  if (showSource)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: playlist.sourceId == 'qqmusic'
                              ? Colors.green.withValues(alpha: 0.85)
                              : Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
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
            const SizedBox(height: 6),
            Text(
              playlist.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 排行榜卡片（展示歌曲预览）──

class _ToplistCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final String sourceLabel;
  final List<String> trackPreviews;
  final VoidCallback? onTap;

  const _ToplistCard({
    required this.name,
    required this.coverUrl,
    required this.sourceLabel,
    this.trackPreviews = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: CachedImage(
                imageUrl: coverUrl,
                width: 110,
                height: 150,
              ),
            ),
            // Info + preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Track previews
                    ...List.generate(
                      trackPreviews.length.clamp(0, 3),
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}. ${trackPreviews[i]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (trackPreviews.isEmpty)
                      Text(
                        '查看完整榜单 >',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
