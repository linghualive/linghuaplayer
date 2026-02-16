import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/storage_service.dart';
import '../../../data/models/search/search_video_model.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/utils/app_toast.dart';
import '../player_controller.dart';

class UploaderWorksSheet extends StatefulWidget {
  const UploaderWorksSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const UploaderWorksSheet(),
      isScrollControlled: true,
    );
  }

  @override
  State<UploaderWorksSheet> createState() => _UploaderWorksSheetState();
}

class _UploaderWorksSheetState extends State<UploaderWorksSheet> {
  final _controller = Get.find<PlayerController>();

  List<MemberSeason> _seasons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    try {
      final result = await _controller.loadUploaderSeasons();
      if (mounted) {
        setState(() {
          _seasons = result.seasons;
          _loading = false;
        });
      }
    } catch (e) {
      log('Load seasons error: $e');
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _controller.currentVideo.value;
    final authorName = video?.author ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '$authorName 的合集',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!_loading)
                  Text(
                    ' (${_seasons.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _seasons.isEmpty
                        ? const Center(child: Text('暂无合集'))
                        : ListView.builder(
                            itemCount: _seasons.length,
                            itemBuilder: (context, index) {
                              return _SeasonTile(
                                season: _seasons[index],
                                controller: _controller,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SeasonTile extends StatefulWidget {
  final MemberSeason season;
  final PlayerController controller;

  const _SeasonTile({required this.season, required this.controller});

  @override
  State<_SeasonTile> createState() => _SeasonTileState();
}

class _SeasonTileState extends State<_SeasonTile> {
  bool _expanded = false;
  bool _loadingDetail = false;
  bool _loadingMore = false;
  bool _actionRunning = false;
  List<SearchVideoModel> _videos = [];
  int _pn = 1;
  int _total = 0;

  bool get _hasMore => _videos.length < _total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: widget.season.cover.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    widget.season.cover.startsWith('//')
                        ? 'https:${widget.season.cover}'
                        : widget.season.cover,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderIcon(context),
                  ),
                )
              : _placeholderIcon(context),
          title: Text(
            widget.season.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${widget.season.total} 个视频'),
          trailing: _loadingDetail
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onTap: _toggleExpand,
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.only(left: 64, right: 16, bottom: 4),
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.playlist_add,
                label: '添加到播放列表',
                enabled: !_actionRunning,
                onPressed: _addAllToQueue,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.favorite_border,
                label: '收藏合集',
                enabled: !_actionRunning,
                onPressed: _favoriteSeason,
              ),
            ],
          ),
        ),
        // Expanded video list
        if (_expanded && _videos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._videos.map((song) {
                  return _VideoTile(
                    song: song,
                    controller: widget.controller,
                  );
                }),
                if (_hasMore)
                  _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : TextButton(
                          onPressed: _loadMore,
                          child: Text(
                            '加载更多 (${_videos.length}/$_total)',
                          ),
                        ),
              ],
            ),
          ),
        if (_expanded && _videos.isEmpty && !_loadingDetail)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('暂无视频'),
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.video_library, size: 24),
    );
  }

  Future<void> _toggleExpand() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    // If already loaded, just expand
    if (_videos.isNotEmpty) {
      setState(() => _expanded = true);
      return;
    }

    // If preview archives cover everything, use them
    if (widget.season.archives.isNotEmpty &&
        widget.season.archives.length >= widget.season.total) {
      setState(() {
        _videos = widget.season.archives;
        _total = widget.season.total;
        _expanded = true;
      });
      return;
    }

    // Load first page
    setState(() => _loadingDetail = true);
    try {
      final page =
          await widget.controller.loadCollectionPage(widget.season, pn: 1);
      if (mounted) {
        setState(() {
          _videos = page.items;
          _total = page.total;
          _pn = 1;
          _loadingDetail = false;
          _expanded = true;
        });
      }
    } catch (e) {
      log('Load collection page error: $e');
      if (mounted) {
        setState(() {
          // Fallback to preview archives
          _videos = widget.season.archives;
          _total = widget.season.total;
          _loadingDetail = false;
          _expanded = true;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final nextPn = _pn + 1;
      final page = await widget.controller
          .loadCollectionPage(widget.season, pn: nextPn);
      if (mounted) {
        setState(() {
          _videos = [..._videos, ...page.items];
          _pn = nextPn;
          _loadingMore = false;
        });
      }
    } catch (e) {
      log('Load more error: $e');
      if (mounted) {
        setState(() => _loadingMore = false);
        AppToast.error('加载更多失败');
      }
    }
  }

  Future<void> _addAllToQueue() async {
    if (_actionRunning) return;
    setState(() => _actionRunning = true);

    try {
      // Load all pages first
      final allVideos = await _loadAllVideos();
      if (allVideos.isEmpty) {
        AppToast.show('合集为空');
        return;
      }

      AppToast.show('正在添加 ${allVideos.length} 个视频...');
      await widget.controller.addAllToQueue(allVideos);
    } catch (e) {
      log('Add all to queue error: $e');
      AppToast.error('添加失败: $e');
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }

  /// Load all pages of videos for batch operations (add-to-queue, favorite).
  Future<List<SearchVideoModel>> _loadAllVideos() async {
    // If preview archives cover everything, use them
    if (widget.season.archives.isNotEmpty &&
        widget.season.archives.length >= widget.season.total) {
      return widget.season.archives;
    }

    final all = <SearchVideoModel>[];
    int pn = 1;
    while (true) {
      final page = await widget.controller
          .loadCollectionPage(widget.season, pn: pn);
      all.addAll(page.items);
      if (page.items.isEmpty || all.length >= page.total) break;
      pn++;
    }

    // Update local state with all loaded videos
    if (mounted) {
      setState(() {
        _videos = all;
        _total = all.length;
        _pn = pn;
      });
    }

    return all;
  }

  Future<void> _favoriteSeason() async {
    if (_actionRunning) return;

    final storage = Get.find<StorageService>();
    if (!storage.isLoggedIn) {
      AppToast.show('请先登录哔哩哔哩');
      return;
    }

    setState(() => _actionRunning = true);

    try {
      // Load all pages first
      final videos = await _loadAllVideos();
      if (videos.isEmpty) {
        AppToast.show('合集为空');
        return;
      }

      final repo = Get.find<UserRepository>();

      // Create a new fav folder
      AppToast.show('正在创建收藏夹...');
      final folderId = await repo.addFavFolder(title: widget.season.name);
      if (folderId == null) {
        AppToast.error('创建收藏夹失败');
        return;
      }

      // Add each video to the folder
      int success = 0;
      int failed = 0;
      for (int i = 0; i < videos.length; i++) {
        final video = videos[i];
        if (video.id <= 0) {
          failed++;
          continue;
        }
        try {
          final ok = await repo.favResourceDeal(
            rid: video.id,
            addIds: [folderId],
            delIds: [],
          );
          if (ok) {
            success++;
          } else {
            failed++;
          }
        } catch (e) {
          log('Fav video ${video.id} error: $e');
          failed++;
        }
        // Show progress every 5 videos
        if ((i + 1) % 5 == 0 && mounted) {
          AppToast.show('收藏进度: ${i + 1}/${videos.length}');
        }
      }

      if (failed == 0) {
        AppToast.show('已收藏 $success 个视频到「${widget.season.name}」');
      } else {
        AppToast.show('收藏完成: $success 成功, $failed 失败');
      }
    } catch (e) {
      log('Favorite season error: $e');
      AppToast.error('收藏失败: $e');
    } finally {
      if (mounted) setState(() => _actionRunning = false);
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: enabled ? onPressed : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _VideoTile extends StatelessWidget {
  final SearchVideoModel song;
  final PlayerController controller;

  const _VideoTile({required this.song, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: song.pic.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song.pic.startsWith('//') ? 'https:${song.pic}' : song.pic,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note, size: 20),
                ),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.music_note, size: 20),
            ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      subtitle: Text(
        song.duration,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.playlist_add, size: 20),
        tooltip: '添加到播放列表',
        onPressed: () async {
          final success = await controller.addToQueueSilent(song);
          if (success) {
            AppToast.show('已添加到播放列表');
          } else {
            AppToast.show('已在播放列表中');
          }
        },
      ),
      onTap: () {
        Get.back();
        controller.playFromSearch(song);
      },
    );
  }
}
