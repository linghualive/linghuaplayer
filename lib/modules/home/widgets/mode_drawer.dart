import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/local_playlist_model.dart';
import '../../../data/services/local_playlist_service.dart';
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
        SizedBox(height: MediaQuery.of(context).padding.top + 12),
        // Quick actions — text chips in a row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              _ActionChip(
                label: '发现',
                onTap: () {
                  _close();
                  Get.toNamed(AppRoutes.musicDiscovery);
                },
              ),
              const SizedBox(width: 8),
              _ActionChip(
                label: '新建',
                onTap: () => CreateFavDialog.show(context),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                label: '导入',
                onTap: () {
                  _close();
                  ImportPlaylistSheet.show(context, 'bilibili');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Section divider with label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                '听歌模式',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Random mode — always visible
        Obx(() {
          final playerCtrl = Get.find<PlayerController>();
          return _RandomModeTile(
            onTap: () {
              _close();
              playerCtrl.playRandomAll();
            },
            isActive: playerCtrl.currentModeId.value == '__random__',
          );
        }),
        // User modes list
        Expanded(
          child: Obx(() {
            final playlists = playlistService.playlists.toList();
            if (playlists.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    '搜索音乐并收藏到模式\n开始你的专属听歌体验',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                  ),
                ),
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: playlists.length,
              onReorder: (oldIndex, newIndex) {
                playlistService.reorderPlaylist(oldIndex, newIndex);
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 2,
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
        // Bottom bar
        Divider(
          height: 0.5,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        _buildBottomBar(context, theme, homeCtrl),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, ThemeData theme, HomeController homeCtrl) {
    return Obx(() {
      final isLoggedIn = homeCtrl.isLoggedIn.value;
      final userName = homeCtrl.userInfo.value?.uname;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            // User / login
            Expanded(
              child: GestureDetector(
                onTap: isLoggedIn
                    ? null
                    : () {
                        _close();
                        Get.toNamed(AppRoutes.login);
                      },
                child: Row(
                  children: [
                    Icon(
                      isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isLoggedIn ? (userName ?? '') : '登录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => homeCtrl.logout(),
                        child: Text(
                          '退出',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // History
            _BottomBarIcon(
              icon: Icons.history_rounded,
              onTap: () {
                _close();
                Get.toNamed(AppRoutes.watchHistory);
              },
            ),
            const SizedBox(width: 4),
            // Settings
            _BottomBarIcon(
              icon: Icons.settings_rounded,
              onTap: () {
                _close();
                Get.toNamed(AppRoutes.settings);
              },
            ),
          ],
        ),
      );
    });
  }
}

class _BottomBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomBarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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

  const _ModeTile(
      {super.key,
      required this.playlist,
      required this.onClose,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerCtrl = Get.find<PlayerController>();

    return Obx(() {
      final isPlaying = playerCtrl.currentModeId.value == playlist.id;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _switchMode(context),
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(10),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                // Left indicator
                Container(
                  width: 3,
                  height: 28,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isPlaying ? FontWeight.w600 : FontWeight.w400,
                          color: isPlaying ? theme.colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${playlist.trackCount} 首',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                          if (playlist.sourceTag != 'local') ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                            _SourceLabel(sourceTag: playlist.sourceTag),
                          ],
                          if (isPlaying) ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '正在播放',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.equalizer_rounded,
                                size: 12,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 18,
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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

class _RandomModeTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  const _RandomModeTile({required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '随机模式',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? theme.colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '打乱所有模式的歌曲',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.shuffle_rounded,
                  size: 18,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceLabel extends StatelessWidget {
  final String sourceTag;
  const _SourceLabel({required this.sourceTag});

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

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color.withValues(alpha: 0.7),
        fontSize: 11,
      ),
    );
  }
}
