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
        SizedBox(height: MediaQuery.of(context).padding.top + 12),
        // App branding
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '玲华',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '多源音乐播放器',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Quick actions — 2×2 grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              Row(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_rounded,
                      label: '新建',
                      onTap: () => CreateFavDialog.show(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.shuffle_rounded,
                      label: '随机',
                      onTap: () {
                        _close();
                        Get.find<PlayerController>().playRandomAll();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                '听歌模式',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
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
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.headphones_rounded,
                            size: 28,
                            color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: _buildBottomSection(context, theme, homeCtrl),
        ),
        Container(
          color: theme.colorScheme.surfaceContainerLow,
          height: MediaQuery.of(context).padding.bottom + 4,
        ),
      ],
    );
  }

  Widget _buildBottomSection(
      BuildContext context, ThemeData theme, HomeController homeCtrl) {
    return Obx(() {
      final isLoggedIn = homeCtrl.isLoggedIn.value;
      final userName = homeCtrl.userInfo.value?.uname;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoggedIn && userName != null)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 16, color: theme.colorScheme.primary),
                ),
                title: Text(userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
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
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.login_rounded,
                      size: 16, color: theme.colorScheme.primary),
                ),
                title: Text('登录哔哩哔哩',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
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
                    leading: Icon(Icons.history_rounded,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    title: Text('历史',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
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
                    leading: Icon(Icons.settings_rounded,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    title: Text('设置',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: isPlaying
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _switchMode(context),
            onLongPress: () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  // Active indicator bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 3,
                    height: isPlaying ? 32 : 0,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isPlaying ? theme.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Cover art
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: isPlaying
                          ? Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isPlaying ? 8.5 : 10),
                      child: playlist.coverUrl.isNotEmpty
                          ? CachedImage(
                              imageUrl: playlist.coverUrl,
                              width: 50,
                              height: 50)
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.6),
                                    theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: Icon(Icons.music_note_rounded,
                                  size: 22, color: theme.colorScheme.primary),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                            color: isPlaying ? theme.colorScheme.primary : null,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (isPlaying) ...[
                              Icon(Icons.equalizer_rounded,
                                  size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '${playlist.trackCount} 首',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isPlaying
                                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                    : theme.colorScheme.outline.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            if (playlist.sourceTag != 'local') ...[
                              const SizedBox(width: 6),
                              _SourceBadge(sourceTag: playlist.sourceTag),
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
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 20,
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
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
        borderRadius: BorderRadius.circular(4),
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
