import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/local_playlist_model.dart';
import '../../shared/utils/app_toast.dart';
import '../../shared/widgets/cached_image.dart';
import '../../shared/widgets/create_fav_dialog.dart';
import 'playlist_controller.dart';
import 'widgets/import_playlist_sheet.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: '导入歌单',
            onSelected: (tag) => ImportPlaylistSheet.show(context, tag),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'bilibili',
                child: Row(
                  children: [
                    Icon(Icons.smart_display, size: 20),
                    SizedBox(width: 8),
                    Text('哔哩哔哩'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'netease',
                child: Row(
                  children: [
                    Icon(Icons.cloud, size: 20),
                    SizedBox(width: 8),
                    Text('网易云音乐'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'qqmusic',
                child: Row(
                  children: [
                    Icon(Icons.queue_music, size: 20),
                    SizedBox(width: 8),
                    Text('QQ音乐'),
                  ],
                ),
              ),
            ],
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
    final theme = Theme.of(context);

    return Obx(() {
      controller.allPlaylists.length;
      controller.searchQuery.value;

      final playlists = controller.filteredPlaylists;

      return Column(
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

          // Playlist list
          Expanded(
            child: playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_music,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          controller.searchQuery.value.isEmpty
                              ? '暂无歌单\n点击 + 新建或导入歌单'
                              : '无匹配结果',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) =>
                        _PlaylistTile(playlist: playlists[index]),
                  ),
          ),
        ],
      );
    });
  }
}

class _PlaylistTile extends StatelessWidget {
  final LocalPlaylist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PlaylistController>();

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: playlist.coverUrl.isNotEmpty
            ? CachedImage(imageUrl: playlist.coverUrl, width: 48, height: 48)
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.queue_music, size: 24),
              ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (playlist.sourceTag != 'local') ...[
            const SizedBox(width: 6),
            _SourceBadge(sourceTag: playlist.sourceTag),
          ],
        ],
      ),
      subtitle: Text('${playlist.trackCount} 首'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed(
        AppRoutes.localPlaylistDetail,
        arguments: {'playlistId': playlist.id},
      ),
      onLongPress: () => _showContextMenu(context, controller),
    );
  }

  void _showContextMenu(BuildContext context, PlaylistController controller) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, controller);
              },
            ),
            if (playlist.remoteId != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('刷新'),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(
                    AppRoutes.localPlaylistDetail,
                    arguments: {'playlistId': playlist.id},
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text('删除',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PlaylistController controller) {
    final textController = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重命名歌单'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: '歌单名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.renamePlaylist(playlist.id, name);
                Navigator.pop(context);
                AppToast.show('已重命名');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, PlaylistController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除「${playlist.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              controller.deletePlaylist(playlist.id);
              Navigator.pop(context);
              AppToast.show('已删除');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String sourceTag;

  const _SourceBadge({required this.sourceTag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _sourceColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _sourceLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  String get _sourceLabel {
    switch (sourceTag) {
      case 'bilibili':
        return 'B站';
      case 'netease':
        return '网易云';
      case 'qqmusic':
        return 'QQ';
      default:
        return sourceTag;
    }
  }

  Color _sourceColor(ThemeData theme) {
    switch (sourceTag) {
      case 'bilibili':
        return const Color(0xFFFB7299);
      case 'netease':
        return const Color(0xFFE60026);
      case 'qqmusic':
        return const Color(0xFF31C27C);
      default:
        return theme.colorScheme.outline;
    }
  }
}
