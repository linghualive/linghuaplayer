import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/search/search_video_model.dart';
import '../../../data/services/local_playlist_service.dart';
import '../../../data/sources/music_source_registry.dart';
import '../../../shared/utils/app_toast.dart';
import '../local_playlist_detail_controller.dart';

class AddSongsSheet extends StatefulWidget {
  final String playlistId;

  const AddSongsSheet({super.key, required this.playlistId});

  static void show(BuildContext context, String playlistId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddSongsSheet(playlistId: playlistId),
    );
  }

  @override
  State<AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<AddSongsSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _results = <SearchVideoModel>[];
  final _existingIds = <String>{};
  bool _isSearching = false;
  int _addedCount = 0;
  int _skippedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingIds();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadExistingIds() {
    final service = Get.find<LocalPlaylistService>();
    final playlist = service.getPlaylist(widget.playlistId);
    if (playlist != null) {
      _existingIds.addAll(playlist.tracks.map((t) => t.uniqueId));
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final registry = Get.find<MusicSourceRegistry>();
      final sources = registry.availableSources;
      final allResults = <SearchVideoModel>[];

      for (final source in sources) {
        try {
          final result = await source.searchTracks(keyword: query.trim());
          allResults.addAll(result.tracks);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _results.clear();
          _results.addAll(allResults);
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addSong(SearchVideoModel song) {
    final service = Get.find<LocalPlaylistService>();
    final added = service.addTrack(widget.playlistId, song);
    setState(() {
      _existingIds.add(song.uniqueId);
      if (added) {
        _addedCount++;
      } else {
        _skippedCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(
              children: [
                Text('添加歌曲',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (_addedCount > 0 || _skippedCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    _skippedCount > 0
                        ? '已添加 $_addedCount 首，跳过 $_skippedCount 首重复'
                        : '已添加 $_addedCount 首',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_addedCount > 0 || _skippedCount > 0) {
                      final msg = _skippedCount > 0
                          ? '已添加 $_addedCount 首，跳过 $_skippedCount 首重复'
                          : '已添加 $_addedCount 首歌曲';
                      AppToast.success(msg);
                      if (Get.isRegistered<LocalPlaylistDetailController>()) {
                        Get.find<LocalPlaylistDetailController>().reload();
                      }
                    }
                  },
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              hintText: '搜索歌曲名或歌手...',
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(Icons.search,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _results.clear());
                    },
                  ),
              ],
              onSubmitted: _search,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHighest,
              ),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              )),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 4),
              ),
              textStyle: WidgetStateProperty.all(theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? '输入关键词搜索歌曲'
                              : '未找到结果',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final song = _results[index];
                          final alreadyAdded =
                              _existingIds.contains(song.uniqueId);
                          return _SongResultTile(
                            song: song,
                            alreadyAdded: alreadyAdded,
                            onAdd: () => _addSong(song),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SongResultTile extends StatelessWidget {
  final SearchVideoModel song;
  final bool alreadyAdded;
  final VoidCallback onAdd;

  const _SongResultTile({
    required this.song,
    required this.alreadyAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: song.pic.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: song.pic,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note, size: 18),
                ),
              )
            : Container(
                width: 44,
                height: 44,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note, size: 18),
              ),
      ),
      title: Text(song.title,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
      trailing: alreadyAdded
          ? Icon(Icons.check_circle,
              size: 22, color: theme.colorScheme.primary)
          : IconButton(
              icon: Icon(Icons.add_circle_outline,
                  size: 22, color: theme.colorScheme.primary),
              onPressed: onAdd,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
    );
  }
}
