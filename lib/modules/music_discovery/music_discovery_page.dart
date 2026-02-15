import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/loading_widget.dart';
import 'music_discovery_controller.dart';
import 'widgets/hot_playlist_card.dart';
import 'widgets/mv_card.dart';
import 'widgets/rank_song_card.dart';
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
            controller.rankSongs.isEmpty &&
            controller.hotPlaylists.isEmpty &&
            controller.mvList.isEmpty) {
          return const LoadingWidget();
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ListView(
            children: [
              // Daily Recommend Songs (NetEase login only)
              if (controller.dailyRecommendSongs.isNotEmpty) ...[
                const SectionHeader(title: '每日推荐'),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.dailyRecommendSongs.length,
                    itemBuilder: (context, index) {
                      final song = controller.dailyRecommendSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              controller.onDailyRecommendSongTap(song),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                ),
                const SizedBox(height: 16),
              ],

              // Daily Recommend Playlists (NetEase login only)
              if (controller.dailyRecommendPlaylists.isNotEmpty) ...[
                const SectionHeader(title: '推荐歌单'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount:
                        controller.dailyRecommendPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist =
                          controller.dailyRecommendPlaylists[index];
                      return _NeteasePlaylistCard(
                        playlist: playlist,
                        onTap: () => Get.toNamed(
                          AppRoutes.neteasePlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Music Ranking Section
              if (controller.rankSongs.isNotEmpty) ...[
                Obx(() => SectionHeader(
                      title: controller.rankTitle.value.isNotEmpty
                          ? '音乐排行榜 · ${controller.rankTitle.value}'
                          : '音乐排行榜',
                      onViewAll: () =>
                          Get.toNamed(AppRoutes.musicRanking),
                    )),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.rankSongs.length,
                    itemBuilder: (context, index) {
                      final song = controller.rankSongs[index];
                      return RankSongCard(
                        song: song,
                        onTap: () => controller.onRankSongTap(song),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Hot Playlists Section
              if (controller.hotPlaylists.isNotEmpty) ...[
                SectionHeader(
                  title: '热门歌单',
                  onViewAll: () => Get.toNamed(AppRoutes.hotPlaylists),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.hotPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = controller.hotPlaylists[index];
                      return HotPlaylistCard(
                        playlist: playlist,
                        onTap: () => Get.toNamed(
                          AppRoutes.audioPlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // MV Section
              if (controller.mvList.isNotEmpty) ...[
                SectionHeader(
                  title: '音乐视频',
                  onViewAll: () => Get.toNamed(AppRoutes.mvList),
                ),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.mvList.length,
                    itemBuilder: (context, index) {
                      final mv = controller.mvList[index];
                      return MvCard(
                        mv: mv,
                        onTap: () => controller.onMvTap(mv),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // NetEase New Songs Section
              if (controller.neteaseNewSongs.isNotEmpty) ...[
                const SectionHeader(title: '新歌速递'),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.neteaseNewSongs.length,
                    itemBuilder: (context, index) {
                      final song = controller.neteaseNewSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              controller.onNeteaseNewSongTap(song),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                ),
                const SizedBox(height: 16),
              ],

              // NetEase Recommend Playlists Section
              if (controller.neteaseRecommendPlaylists.isNotEmpty) ...[
                const SectionHeader(title: '推荐歌单'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount:
                        controller.neteaseRecommendPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist =
                          controller.neteaseRecommendPlaylists[index];
                      return _NeteasePlaylistCard(
                        playlist: playlist,
                        onTap: () => Get.toNamed(
                          AppRoutes.neteasePlaylistDetail,
                          arguments: playlist,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      }),
    );
  }
}

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
