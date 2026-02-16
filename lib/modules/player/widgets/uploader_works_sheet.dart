import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/search/search_video_model.dart';
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
  List<SearchVideoModel> _works = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    final results = await _controller.loadUploaderWorks();
    if (mounted) {
      setState(() {
        _works = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _controller.currentVideo.value;
    final headerTitle =
        video?.isNetease == true ? '歌手的作品' : 'UP主的作品';
    final authorName = video?.author ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
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
            padding: const EdgeInsets.only(top: 12, bottom: 8),
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
                    '$headerTitle - $authorName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '(${_works.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _works.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('暂无作品')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _works.length,
                        itemBuilder: (context, index) {
                          final song = _works[index];
                          return ListTile(
                            leading: song.pic.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      song.pic.startsWith('//')
                                          ? 'https:${song.pic}'
                                          : song.pic,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.music_note,
                                            size: 24),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.music_note,
                                        size: 24),
                                  ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${song.author}  ${song.duration}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.playlist_add, size: 20),
                              tooltip: '添加到播放列表',
                              onPressed: () async {
                                final success = await _controller
                                    .addToQueueSilent(song);
                                if (success) {
                                  AppToast.show('已添加到播放列表');
                                } else {
                                  AppToast.show('已在播放列表中');
                                }
                              },
                            ),
                            onTap: () {
                              Get.back();
                              _controller.playFromSearch(song);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
