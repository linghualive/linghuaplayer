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
        SizedBox(height: MediaQuery.of(context).padding.top + 16),
        // Quick actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _ActionChip(
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
                child: _ActionChip(
                  icon: Icons.add_rounded,
                  label: '新建',
                  onTap: () => CreateFavDialog.show(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.downloading_rounded,
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
        const SizedBox(height: 20),
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '听歌模式',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Random mode
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 36,
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '搜索音乐并收藏到模式\n开始你的专属听歌体验',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          height: 1.6,
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
                  shadowColor: Colors.black26,
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
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: _buildBottomBar(context, theme, homeCtrl),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 2),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, ThemeData theme, HomeController homeCtrl) {
    return Obx(() {
      final isLoggedIn = homeCtrl.isLoggedIn.value;
      final userName = homeCtrl.userInfo.value?.uname;

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        child: Row(
          children: [
            // User avatar
            GestureDetector(
              onTap: isLoggedIn
                  ? null
                  : () {
                      _close();
                      Get.toNamed(AppRoutes.login);
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLoggedIn
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      isLoggedIn
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 16,
                      color: isLoggedIn
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      isLoggedIn ? (userName ?? '') : '登录',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => homeCtrl.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          '退出',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            _BottomBarIcon(
              icon: Icons.history_rounded,
              onTap: () {
                _close();
                Get.toNamed(AppRoutes.watchHistory);
              },
            ),
            _BottomBarIcon(
              icon: Icons.settings_outlined,
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
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 19),
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Material(
          color: isPlaying
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _switchMode(context),
            onLongPress: () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  // Left indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: 24,
                    margin: const EdgeInsets.only(right: 10),
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
                            color: isPlaying
                                ? theme.colorScheme.primary
                                : null,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${playlist.trackCount} 首',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                            if (playlist.sourceTag != 'local') ...[
                              const SizedBox(width: 6),
                              _SourceBadge(sourceTag: playlist.sourceTag),
                            ],
                            if (isPlaying) ...[
                              const SizedBox(width: 6),
                              _PlayingIndicator(
                                color: theme.colorScheme.primary,
                              ),
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
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
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
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 24,
                  margin: const EdgeInsets.only(right: 10),
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
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? theme.colorScheme.primary : null,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '打乱所有模式的歌曲',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shuffle_rounded,
                    size: 15,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String sourceTag;
  const _SourceBadge({required this.sourceTag});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (sourceTag) {
      'bilibili' => (const Color(0xFFFB7299), 'B站'),
      'gdstudio' => (Colors.orange, 'GD'),
      _ => (Theme.of(context).colorScheme.outline, sourceTag),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PlayingIndicator extends StatelessWidget {
  final Color color;
  const _PlayingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.equalizer_rounded,
            size: 13, color: color.withValues(alpha: 0.6)),
      ],
    );
  }
}
