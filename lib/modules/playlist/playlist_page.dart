import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../modules/home/home_controller.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/create_fav_dialog.dart';
import 'playlist_controller.dart';
import 'widgets/playlist_config_sheet.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建歌单',
            onPressed: () => CreateFavDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => PlaylistConfigSheet.show(context),
          ),
        ],
      ),
      body: const _PlaylistBody(),
    );
  }
}

class _PlaylistBody extends StatelessWidget {
  const _PlaylistBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlaylistController>();
    final homeController = Get.find<HomeController>();

    return Obx(() {
      final biliLoggedIn = homeController.isLoggedIn.value;
      final neteaseLoggedIn = homeController.isNeteaseLoggedIn.value;
      final qqMusicLoggedIn = homeController.isQqMusicLoggedIn.value;
      final biliLoading = controller.isLoading.value;
      final neteaseLoading = controller.neteaseIsLoading.value;
      final qqMusicLoading = controller.qqMusicIsLoading.value;
      controller.searchQuery.value;
      controller.visibleFolders.length;
      controller.neteasePlaylists.length;
      controller.qqMusicPlaylists.length;

      final biliFolders = controller.filteredFolders;
      final neteasePlaylists = controller.filteredNeteasePlaylists;
      final qqMusicPlaylists = controller.filteredQqMusicPlaylists;

      return ListView(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索歌单...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              onChanged: (v) => controller.searchQuery.value = v,
            ),
          ),

          // ── Bilibili section ──
          _SectionHeader(
            title: '哔哩哔哩收藏夹',
            icon: Icons.smart_display,
          ),
          if (!biliLoggedIn)
            _LoginPromptCard(
              icon: Icons.smart_display_outlined,
              label: '登录哔哩哔哩查看收藏夹',
              onTap: () => Get.toNamed(AppRoutes.login),
            )
          else if (biliLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (biliFolders.isEmpty)
            _EmptyHint(
              text: controller.searchQuery.value.isEmpty
                  ? '暂无收藏夹'
                  : '无匹配结果',
            )
          else
            ...biliFolders.map((folder) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedImage(
                      imageUrl: folder.cover,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  title: Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${folder.mediaCount} 个内容'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(
                    AppRoutes.favoriteDetail,
                    arguments: {
                      'mediaId': folder.id,
                      'title': folder.title,
                    },
                  ),
                )),

          const SizedBox(height: 8),

          // ── Netease section ──
          _SectionHeader(
            title: '网易云歌单',
            icon: Icons.cloud,
          ),
          if (!neteaseLoggedIn)
            _LoginPromptCard(
              icon: Icons.cloud_outlined,
              label: '登录网易云查看歌单',
              onTap: () => Get.toNamed(
                AppRoutes.login,
                arguments: {'platform': 1},
              ),
            )
          else if (neteaseLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (neteasePlaylists.isEmpty)
            _EmptyHint(
              text: controller.searchQuery.value.isEmpty
                  ? '暂无歌单'
                  : '无匹配结果',
            )
          else
            ...neteasePlaylists.map((playlist) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedImage(
                      imageUrl: playlist.coverUrl,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${playlist.playCount} 次播放'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(
                    AppRoutes.neteasePlaylistDetail,
                    arguments: {
                      'playlistId': playlist.id,
                      'title': playlist.name,
                    },
                  ),
                )),

          const SizedBox(height: 8),

          // ── QQ Music section ──
          _SectionHeader(
            title: 'QQ音乐歌单',
            icon: Icons.queue_music,
          ),
          if (!qqMusicLoggedIn)
            _LoginPromptCard(
              icon: Icons.queue_music_outlined,
              label: '登录QQ音乐查看歌单',
              onTap: () => Get.toNamed(
                AppRoutes.login,
                arguments: {'platform': 2},
              ),
            )
          else if (qqMusicLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (qqMusicPlaylists.isEmpty)
            _EmptyHint(
              text: controller.searchQuery.value.isEmpty
                  ? '暂无歌单'
                  : '无匹配结果',
            )
          else
            ...qqMusicPlaylists.map((playlist) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedImage(
                      imageUrl: playlist.coverUrl,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${playlist.songCount} 首'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(
                    AppRoutes.qqMusicPlaylistDetail,
                    arguments: {
                      'disstid': playlist.id,
                      'title': playlist.name,
                    },
                  ),
                )),
        ],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LoginPromptCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Icon(icon, size: 32, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: const Text('去登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}
