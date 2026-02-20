import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/local_playlist_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/services/local_playlist_service.dart';
import '../utils/app_toast.dart';
import 'create_fav_dialog.dart';

/// Universal "Add to Playlist" panel.
///
/// Works with any [SearchVideoModel] regardless of source.
/// Shows all local playlists and lets the user pick one or more.
class FavPanel extends StatefulWidget {
  final SearchVideoModel video;

  const FavPanel({super.key, required this.video});

  @override
  State<FavPanel> createState() => _FavPanelState();

  /// Show the panel as a bottom sheet.
  static void show(BuildContext context, SearchVideoModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FavPanel(video: video),
    );
  }
}

class _FavPanelState extends State<FavPanel> {
  final _service = Get.find<LocalPlaylistService>();
  late Map<String, bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = {};
    for (final p in _service.playlists) {
      _checked[p.id] = p.tracks.any((t) => t.uniqueId == widget.video.uniqueId);
    }
  }

  void _onConfirm() {
    int added = 0;
    int removed = 0;

    for (final p in _service.playlists) {
      final wasIn =
          p.tracks.any((t) => t.uniqueId == widget.video.uniqueId);
      final isChecked = _checked[p.id] ?? false;

      if (isChecked && !wasIn) {
        _service.addTrack(p.id, widget.video);
        added++;
      } else if (!isChecked && wasIn) {
        _service.removeTrack(p.id, widget.video.uniqueId);
        removed++;
      }
    }

    Navigator.pop(context);

    if (added > 0 && removed > 0) {
      AppToast.show('已添加到 $added 个歌单，从 $removed 个歌单移除');
    } else if (added > 0) {
      AppToast.show('已添加到 $added 个歌单');
    } else if (removed > 0) {
      AppToast.show('已从 $removed 个歌单移除');
    }
  }

  void _onCreated() {
    // Refresh the checked map with the newly created playlist
    setState(() {
      for (final p in _service.playlists) {
        _checked.putIfAbsent(p.id, () => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Obx(() {
        final playlists = _service.playlists.toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '收藏到歌单',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      CreateFavDialog.show(context, onCreated: _onCreated);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建'),
                  ),
                ],
              ),
            ),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无歌单，请先新建一个'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return CheckboxListTile(
                      title: Text(playlist.name),
                      subtitle: Text(
                        '${playlist.trackCount} 首 · ${_sourceLabel(playlist.sourceTag)}',
                      ),
                      value: _checked[playlist.id] ?? false,
                      onChanged: (val) {
                        setState(
                            () => _checked[playlist.id] = val ?? false);
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onConfirm,
                      child: const Text('确认'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _sourceLabel(String sourceTag) {
    switch (sourceTag) {
      case 'bilibili':
        return 'B站';
      case 'netease':
        return '网易云';
      case 'qqmusic':
        return 'QQ音乐';
      case 'local':
        return '本地';
      default:
        return sourceTag;
    }
  }
}
