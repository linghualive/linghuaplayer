import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../playlist_controller.dart';

class PlaylistConfigSheet extends StatefulWidget {
  const PlaylistConfigSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PlaylistConfigSheet(),
    );
  }

  @override
  State<PlaylistConfigSheet> createState() => _PlaylistConfigSheetState();
}

class _PlaylistConfigSheetState extends State<PlaylistConfigSheet> {
  final _controller = Get.find<PlaylistController>();
  late Map<int, bool> _visible;

  @override
  void initState() {
    super.initState();
    final visibleIds =
        _controller.visibleFolders.map((f) => f.id).toSet();
    _visible = {
      for (final f in _controller.folders) f.id: visibleIds.contains(f.id),
    };
  }

  void _onSave() {
    final ids = _visible.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    _controller.saveVisibleConfig(ids);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '显示的收藏夹',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_controller.folders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无收藏夹'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _controller.folders.length,
                itemBuilder: (context, index) {
                  final folder = _controller.folders[index];
                  return SwitchListTile(
                    title: Text(folder.title),
                    subtitle: Text('${folder.mediaCount}个内容'),
                    value: _visible[folder.id] ?? false,
                    onChanged: (val) {
                      setState(() => _visible[folder.id] = val);
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSave,
                child: const Text('保存'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
