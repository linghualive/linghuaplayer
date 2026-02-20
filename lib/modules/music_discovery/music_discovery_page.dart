import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/browse_models.dart';
import '../../data/models/genre_categories.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/loading_widget.dart';
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
            controller.neteaseNewSongs.isEmpty &&
            controller.curatedPlaylists.isEmpty) {
          return const LoadingWidget();
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView(
            padding: const EdgeInsets.only(top: 4),
            children: [
              // ── 1. 每日推荐（需网易云登录）──
              if (controller.dailyRecommendSongs.isNotEmpty ||
                  controller.dailyRecommendPlaylists.isNotEmpty) ...[
                if (controller.dailyRecommendSongs.isNotEmpty) ...[
                  const SectionHeader(title: '每日推荐'),
                  _buildHorizontalSongList(
                    songs: controller.dailyRecommendSongs,
                    onTap: controller.onDailyRecommendSongTap,
                    theme: theme,
                  ),
                ],
                if (controller.dailyRecommendPlaylists.isNotEmpty) ...[
                  const SectionHeader(title: '每日推荐歌单'),
                  _buildNeteasePlaylistGrid(
                    playlists: controller.dailyRecommendPlaylists,
                  ),
                ],
              ],

              // ── 2. 新歌速递 ──
              if (controller.neteaseNewSongs.isNotEmpty) ...[
                const SectionHeader(title: '新歌速递'),
                _buildHorizontalSongList(
                  songs: controller.neteaseNewSongs,
                  onTap: controller.onNeteaseNewSongTap,
                  theme: theme,
                ),
              ],

              // ── 3. 精选歌单推荐 ──
              if (controller.curatedPlaylists.isNotEmpty) ...[
                SectionHeader(
                  title: '精选歌单推荐',
                  onViewAll: () =>
                      Get.toNamed(AppRoutes.neteaseHotPlaylists),
                ),
                _buildUnifiedPlaylistGrid(
                  playlists: controller.curatedPlaylists,
                  onTap: controller.navigateToPlaylist,
                  theme: theme,
                ),
              ],

              // ── 4. 多源排行榜 ──
              if (controller.neteaseToplistPreview.isNotEmpty ||
                  controller.qqMusicToplistPreview.isNotEmpty) ...[
                const SectionHeader(title: '多源排行榜'),
                if (controller.neteaseToplistPreview.isNotEmpty) ...[
                  _buildSourceLabel('网易云', theme),
                  _buildNeteaseToplistRow(controller, theme),
                ],
                if (controller.qqMusicToplistPreview.isNotEmpty) ...[
                  _buildSourceLabel('QQ音乐', theme),
                  _buildQqToplistRow(controller, theme),
                ],
              ],

              // ── 5. 风格分类歌单 ──
              _buildGenreSection(controller, theme),

              // ── 6. 热门歌手推荐 ──
              _buildSingerSection(controller, theme),

              // 底部留白
              const SizedBox(height: 64),
            ],
          ),
        );
      }),
    );
  }

  // ── 通用水平歌曲列表 ──

  Widget _buildHorizontalSongList({
    required List<SearchVideoModel> songs,
    required void Function(SearchVideoModel) onTap,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onTap(song),
              child: SizedBox(
                width: 200,
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
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
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

  // ── 网易云歌单网格（NeteasePlaylistBrief）──

  Widget _buildNeteasePlaylistGrid({
    required List<NeteasePlaylistBrief> playlists,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _NeteasePlaylistCard(
            playlist: playlist,
            onTap: () => Get.toNamed(
              AppRoutes.neteasePlaylistDetail,
              arguments: playlist,
            ),
          );
        },
      ),
    );
  }

  // ── 统一歌单网格（PlaylistBrief，多源）──

  Widget _buildUnifiedPlaylistGrid({
    required List<PlaylistBrief> playlists,
    required void Function(PlaylistBrief) onTap,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _UnifiedPlaylistCard(
            playlist: playlist,
            onTap: () => onTap(playlist),
          );
        },
      ),
    );
  }

  // ── 来源标签 ──

  Widget _buildSourceLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
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

  // ── 网易云排行榜横向滚动 ──

  Widget _buildNeteaseToplistRow(
      MusicDiscoveryController controller, ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.neteaseToplistPreview.length,
        itemBuilder: (context, index) {
          final toplist = controller.neteaseToplistPreview[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.neteasePlaylistDetail,
                arguments: toplist.id,
              ),
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    CachedImage(
                      imageUrl: toplist.coverUrl,
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toplist.name,
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
  }

  // ── QQ音乐排行榜横向滚动 ──

  Widget _buildQqToplistRow(
      MusicDiscoveryController controller, ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.qqMusicToplistPreview.length,
        itemBuilder: (context, index) {
          final toplist = controller.qqMusicToplistPreview[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Get.toNamed(
                AppRoutes.qqMusicPlaylistDetail,
                arguments: {
                  'disstid': toplist.id,
                  'title': toplist.name,
                },
              ),
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    CachedImage(
                      imageUrl: toplist.coverUrl,
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toplist.name,
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
  }

  // ── 风格分类歌单板块 ──

  Widget _buildGenreSection(
      MusicDiscoveryController controller, ThemeData theme) {
    // Flatten all genre tags for the selector
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
        const SizedBox(height: 4),
        // Genre playlists grid
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
          return _buildNeteasePlaylistGrid(
            playlists: controller.genrePlaylists,
          );
        }),
      ],
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
        const SectionHeader(title: '热门歌手推荐'),
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
        const SizedBox(height: 4),
        // Singer horizontal scroll
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
            height: 100,
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
                            width: 64,
                            height: 64,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          const SizedBox(height: 4),
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

// ── 网易云歌单卡片 ──

class _NeteasePlaylistCard extends StatelessWidget {
  final NeteasePlaylistBrief playlist;
  final VoidCallback? onTap;

  const _NeteasePlaylistCard({required this.playlist, this.onTap});

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
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatPlayCount(playlist.playCount),
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

// ── 统一歌单卡片（PlaylistBrief）──

class _UnifiedPlaylistCard extends StatelessWidget {
  final PlaylistBrief playlist;
  final VoidCallback? onTap;

  const _UnifiedPlaylistCard({required this.playlist, this.onTap});

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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatPlayCount(playlist.playCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                // Source badge
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
