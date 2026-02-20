import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../data/models/search/search_video_model.dart';
import '../../../data/models/user/fav_folder_model.dart';
import '../../../data/repositories/netease_repository.dart';
import '../../../data/repositories/qqmusic_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/local_playlist_service.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/cached_image.dart';

class ImportPlaylistSheet extends StatefulWidget {
  final String sourceTag;
  final ScrollController? scrollController;

  const ImportPlaylistSheet({
    super.key,
    required this.sourceTag,
    this.scrollController,
  });

  static void show(BuildContext context, String sourceTag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ImportPlaylistSheet(
          sourceTag: sourceTag,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<ImportPlaylistSheet> createState() => _ImportPlaylistSheetState();
}

class _ImportPlaylistSheetState extends State<ImportPlaylistSheet> {
  final _playlistService = Get.find<LocalPlaylistService>();
  final _storage = Get.find<StorageService>();

  bool _loading = true;
  final _importingIds = <String>{};

  List<FavFolderModel> _biliFolders = [];
  List<NeteasePlaylistBrief> _neteasePlaylists = [];
  List<QqMusicPlaylistBrief> _qqMusicPlaylists = [];

  ScrollController get _scrollController =>
      widget.scrollController ?? ScrollController();

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      _loadPlaylists();
    } else {
      _loading = false;
    }
  }

  bool get _isLoggedIn {
    switch (widget.sourceTag) {
      case 'bilibili':
        return _storage.isLoggedIn;
      case 'netease':
        return _storage.isNeteaseLoggedIn;
      case 'qqmusic':
        return _storage.isQqMusicLoggedIn;
      default:
        return false;
    }
  }

  int get _loginPlatformIndex {
    switch (widget.sourceTag) {
      case 'bilibili':
        return 0;
      case 'netease':
        return 1;
      case 'qqmusic':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _goToLogin() async {
    // Close the sheet first, then navigate to login
    Navigator.pop(context);
    await Get.toNamed(
      AppRoutes.login,
      arguments: {'platform': _loginPlatformIndex},
    );
    // After returning from login, if the user navigates back to import,
    // the sheet will re-check login state in initState
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    try {
      switch (widget.sourceTag) {
        case 'bilibili':
          final mid = int.tryParse(_storage.userMid ?? '') ?? 0;
          if (mid > 0) {
            final repo = Get.find<UserRepository>();
            _biliFolders = await repo.getFavFolders(upMid: mid);
          }
          break;
        case 'netease':
          final uid = int.tryParse(_storage.neteaseUserId ?? '') ?? 0;
          if (uid > 0) {
            final repo = Get.find<NeteaseRepository>();
            _neteasePlaylists = await repo.getUserPlaylists(uid);
          }
          break;
        case 'qqmusic':
          final uin = _storage.qqMusicUin ?? '';
          if (uin.isNotEmpty) {
            final repo = Get.find<QqMusicRepository>();
            _qqMusicPlaylists = await repo.getUserPlaylists(uin);
          }
          break;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool _isImported(String remoteId) {
    return _playlistService.findByRemoteId(widget.sourceTag, remoteId) != null;
  }

  Future<void> _importBiliFolder(FavFolderModel folder) async {
    final remoteId = folder.id.toString();
    setState(() => _importingIds.add(remoteId));

    try {
      final repo = Get.find<UserRepository>();
      final allTracks = <SearchVideoModel>[];
      int page = 1;
      bool hasMore = true;
      while (hasMore) {
        final result =
            await repo.getFavResources(mediaId: folder.id, pn: page, ps: 20);
        allTracks.addAll(result.items.map((e) => e.toSearchVideoModel()));
        hasMore = result.hasMore;
        page++;
      }

      final existing = _playlistService.findByRemoteId('bilibili', remoteId);
      if (existing != null) {
        _playlistService.refreshPlaylist(existing.id, allTracks);
        AppToast.show('已更新「${folder.title}」');
      } else {
        _playlistService.importPlaylist(
          name: folder.title,
          coverUrl: folder.cover,
          sourceTag: 'bilibili',
          remoteId: remoteId,
          tracks: allTracks,
          creatorName: folder.name,
        );
        AppToast.show('已导入「${folder.title}」');
      }
    } catch (e) {
      AppToast.error('导入失败');
    }

    if (mounted) setState(() => _importingIds.remove(remoteId));
  }

  Future<void> _importNeteasePlaylist(NeteasePlaylistBrief playlist) async {
    final remoteId = playlist.id.toString();
    setState(() => _importingIds.add(remoteId));

    try {
      final repo = Get.find<NeteaseRepository>();
      final detail = await repo.getPlaylistDetail(playlist.id);
      if (detail == null) {
        AppToast.error('获取歌单详情失败');
        if (mounted) setState(() => _importingIds.remove(remoteId));
        return;
      }

      final existing = _playlistService.findByRemoteId('netease', remoteId);
      if (existing != null) {
        _playlistService.refreshPlaylist(existing.id, detail.tracks);
        AppToast.show('已更新「${playlist.name}」');
      } else {
        _playlistService.importPlaylist(
          name: playlist.name,
          coverUrl: playlist.coverUrl,
          sourceTag: 'netease',
          remoteId: remoteId,
          tracks: detail.tracks,
          creatorName: detail.creatorName,
          description: detail.description,
        );
        AppToast.show('已导入「${playlist.name}」');
      }
    } catch (e) {
      AppToast.error('导入失败');
    }

    if (mounted) setState(() => _importingIds.remove(remoteId));
  }

  Future<void> _importQqMusicPlaylist(QqMusicPlaylistBrief playlist) async {
    final remoteId = playlist.id;
    setState(() => _importingIds.add(remoteId));

    try {
      final repo = Get.find<QqMusicRepository>();
      final detail = await repo.getPlaylistDetail(playlist.id);
      if (detail == null) {
        AppToast.error('获取歌单详情失败');
        if (mounted) setState(() => _importingIds.remove(remoteId));
        return;
      }

      final existing = _playlistService.findByRemoteId('qqmusic', remoteId);
      if (existing != null) {
        _playlistService.refreshPlaylist(existing.id, detail.tracks);
        AppToast.show('已更新「${playlist.name}」');
      } else {
        _playlistService.importPlaylist(
          name: playlist.name,
          coverUrl: playlist.coverUrl,
          sourceTag: 'qqmusic',
          remoteId: remoteId,
          tracks: detail.tracks,
          creatorName: detail.creatorName,
          description: detail.description,
        );
        AppToast.show('已导入「${playlist.name}」');
      }
    } catch (e) {
      AppToast.error('导入失败');
    }

    if (mounted) setState(() => _importingIds.remove(remoteId));
  }

  String get _platformTitle {
    switch (widget.sourceTag) {
      case 'bilibili':
        return '哔哩哔哩';
      case 'netease':
        return '网易云音乐';
      case 'qqmusic':
        return 'QQ音乐';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            '导入$_platformTitle歌单',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Content
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              '需要先登录$_platformTitle才能导入歌单',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.login),
              label: Text('登录$_platformTitle'),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _buildItems();
    if (items.isEmpty) {
      return Center(
        child: Text(
          '暂无可导入的歌单',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  List<Widget> _buildItems() {
    switch (widget.sourceTag) {
      case 'bilibili':
        return _biliFolders.map((f) => _buildBiliItem(f)).toList();
      case 'netease':
        return _neteasePlaylists.map((p) => _buildNeteaseItem(p)).toList();
      case 'qqmusic':
        return _qqMusicPlaylists.map((p) => _buildQqMusicItem(p)).toList();
      default:
        return [];
    }
  }

  Widget _buildBiliItem(FavFolderModel folder) {
    final remoteId = folder.id.toString();
    final imported = _isImported(remoteId);
    final importing = _importingIds.contains(remoteId);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedImage(imageUrl: folder.cover, width: 48, height: 48),
      ),
      title: Text(folder.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${folder.mediaCount} 个内容'),
      trailing: _buildActionButton(
        imported: imported,
        importing: importing,
        onTap: () => _importBiliFolder(folder),
      ),
    );
  }

  Widget _buildNeteaseItem(NeteasePlaylistBrief playlist) {
    final remoteId = playlist.id.toString();
    final imported = _isImported(remoteId);
    final importing = _importingIds.contains(remoteId);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child:
            CachedImage(imageUrl: playlist.coverUrl, width: 48, height: 48),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${playlist.playCount} 次播放'),
      trailing: _buildActionButton(
        imported: imported,
        importing: importing,
        onTap: () => _importNeteasePlaylist(playlist),
      ),
    );
  }

  Widget _buildQqMusicItem(QqMusicPlaylistBrief playlist) {
    final remoteId = playlist.id;
    final imported = _isImported(remoteId);
    final importing = _importingIds.contains(remoteId);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child:
            CachedImage(imageUrl: playlist.coverUrl, width: 48, height: 48),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${playlist.songCount} 首'),
      trailing: _buildActionButton(
        imported: imported,
        importing: importing,
        onTap: () => _importQqMusicPlaylist(playlist),
      ),
    );
  }

  Widget _buildActionButton({
    required bool imported,
    required bool importing,
    required VoidCallback onTap,
  }) {
    if (importing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return FilledButton.tonal(
      onPressed: onTap,
      child: Text(imported ? '更新' : '导入'),
    );
  }
}
