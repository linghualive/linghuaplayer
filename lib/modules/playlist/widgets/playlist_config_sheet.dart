import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/local_playlist_service.dart';

class PlaylistConfigSheet extends StatelessWidget {
  const PlaylistConfigSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const PlaylistConfigSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<LocalPlaylistService>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Obx(() {
        final total = service.playlists.length;
        final bySource = service.playlistsBySource;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('歌单统计', style: theme.textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.library_music),
              title: const Text('全部歌单'),
              trailing: Text('$total'),
            ),
            for (final entry in bySource.entries)
              ListTile(
                leading: Icon(_iconFor(entry.key)),
                title: Text(_labelFor(entry.key)),
                trailing: Text('${entry.value.length}'),
              ),
            const SizedBox(height: 8),
          ],
        );
      }),
    );
  }

  static IconData _iconFor(String source) {
    switch (source) {
      case 'bilibili':
        return Icons.smart_display;
      case 'netease':
        return Icons.cloud;
      case 'qqmusic':
        return Icons.queue_music;
      default:
        return Icons.library_music;
    }
  }

  static String _labelFor(String source) {
    switch (source) {
      case 'bilibili':
        return '哔哩哔哩';
      case 'netease':
        return '网易云';
      case 'qqmusic':
        return 'QQ音乐';
      case 'local':
        return '本地创建';
      default:
        return source;
    }
  }
}
