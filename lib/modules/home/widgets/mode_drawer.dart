import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/local_playlist_model.dart';
import '../../../data/services/local_playlist_service.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/create_fav_dialog.dart';
import '../../player/player_controller.dart';
import '../../playlist/widgets/import_playlist_sheet.dart';
import '../home_controller.dart';

class ModeDrawer extends StatelessWidget {
  final VoidCallback? onClose;

  const ModeDrawer({super.key, this.onClose});

  void _close() => onClose?.call();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeCtrl = Get.find<HomeController>();
    final playlistService = Get.find<LocalPlaylistService>();

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 8),
        // Quick actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.explore_outlined,
                  label: '发现',
                  onTap: () {
                    _close();
                    Get.toNamed(AppRoutes.musicDiscovery);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_rounded,
                  label: '新建',
                  onTap: () => CreateFavDialog.show(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionCard(
                  icon: Icons.download_rounded,
                  label: '导入',
                  onTap: () {
                    _close();
                    ImportPlaylistSheet.show(context, 'bilibili');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              Text(
                '听歌模式',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Modes list
        Expanded(
          child: Obx(() {
            final playlists = playlistService.playlists.toList();
            if (playlists.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headphones_rounded,
                          size: 40,
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        '搜索音乐并收藏到模式\n开始你的专属听歌体验',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: playlists.length,
              onReorder: (oldIndex, newIndex) {
                playlistService.reorderPlaylist(oldIndex, newIndex);
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: child,
                );
              },
              itemBuilder: (context, index) => _ModeTile(
                key: ValueKey(playlists[index].id),
                playlist: playlists[index],
                onClose: _close,
                index: index,
              ),
            );
          }),
        ),
        // Bottom section
        const Divider(height: 1, indent: 16, endIndent: 16),
        _buildBottomSection(context, theme, homeCtrl),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
      ],
    );
  }

  Widget _buildBottomSection(
      BuildContext context, ThemeData theme, HomeController homeCtrl) {
    return Obx(() {
      final isLoggedIn = homeCtrl.isLoggedIn.value;
      final userName = homeCtrl.userInfo.value?.uname;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoggedIn && userName != null)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.person_outline, size: 18),
                title: Text(userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
                trailing: TextButton(
                  onPressed: () => homeCtrl.logout(),
                  child: Text('退出',
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 11)),
                ),
              )
            else
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.login, size: 18),
                title:
                    Text('登录哔哩哔哩', style: theme.textTheme.bodySmall),
                onTap: () {
                  _close();
                  Get.toNamed(AppRoutes.login);
                },
              ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.history, size: 18),
                    title: Text('历史', style: theme.textTheme.bodySmall),
                    onTap: () {
                      _close();
                      Get.toNamed(AppRoutes.watchHistory);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.settings_outlined, size: 18),
                    title: Text('设置', style: theme.textTheme.bodySmall),
                    onTap: () {
                      _close();
                      Get.toNamed(AppRoutes.settings);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final LocalPlaylist playlist;
  final VoidCallback onClose;
  final int index;

  const _ModeTile({super.key, required this.playlist, required this.onClose, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _switchMode(context),
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: playlist.coverUrl.isNotEmpty
                    ? CachedImage(
                        imageUrl: playlist.coverUrl, width: 44, height: 44)
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.music_note_rounded,
                            size: 20, color: theme.colorScheme.primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (playlist.sourceTag != 'local') ...[
                          const SizedBox(width: 6),
                          _SourceBadge(sourceTag: playlist.sourceTag),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.trackCount} 首',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 20,
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchMode(BuildContext context) {
    onClose();
    if (playlist.trackCount == 0) {
      Get.toNamed(
        AppRoutes.localPlaylistDetail,
        arguments: {'playlistId': playlist.id},
      );
      return;
    }
    final playerCtrl = Get.find<PlayerController>();
    final tracks = playlist.tracks;
    playerCtrl.playAllFromList(tracks, modeId: playlist.id);
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    final playlistService = Get.find<LocalPlaylistService>();

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('播放此模式'),
              onTap: () {
                Get.back();
                _switchMode(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_rounded),
              title: const Text('查看歌曲'),
              onTap: () {
                Get.back();
                onClose();
                Get.toNamed(
                  AppRoutes.localPlaylistDetail,
                  arguments: {'playlistId': playlist.id},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, playlistService);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: theme.colorScheme.error),
              title:
                  Text('删除', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, playlistService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, LocalPlaylistService service) {
    final textController = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('重命名模式'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: '模式名称'),
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
                service.renamePlaylist(playlist.id, name);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, LocalPlaylistService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除模式'),
        content: Text('确定要删除「${playlist.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              service.deletePlaylist(playlist.id);
              Navigator.pop(context);
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
    final color = switch (sourceTag) {
      'bilibili' => const Color(0xFFFB7299),
      'gdstudio' => Colors.orange,
      _ => theme.colorScheme.outline,
    };
    final label = switch (sourceTag) {
      'bilibili' => 'B站',
      'gdstudio' => 'GD',
      _ => sourceTag,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
