import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
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
            ],
          ),
        );
      }),
    );
  }
}
