import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../music_discovery/widgets/hot_playlist_card.dart';
import 'hot_playlists_controller.dart';

class HotPlaylistsPage extends StatelessWidget {
  const HotPlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HotPlaylistsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('热门歌单')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.playlists.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: controller.loadPlaylists,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: controller.playlists.length +
                  (controller.hasMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.playlists.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final playlist = controller.playlists[index];
                return HotPlaylistCard(
                  playlist: playlist,
                  onTap: () => controller.onPlaylistTap(playlist),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
