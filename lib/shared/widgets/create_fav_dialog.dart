import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/local_playlist_service.dart';
import '../utils/app_toast.dart';

class CreateFavDialog extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateFavDialog({super.key, this.onCreated});

  static void show(BuildContext context, {VoidCallback? onCreated}) {
    showDialog(
      context: context,
      builder: (_) => CreateFavDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreateFavDialog> createState() => _CreateFavDialogState();
}

class _CreateFavDialogState extends State<CreateFavDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onCreate() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.show('请输入歌单名称');
      return;
    }

    final service = Get.find<LocalPlaylistService>();
    service.createPlaylist(title, description: _descController.text.trim());

    Navigator.pop(context);
    AppToast.show('创建成功');
    widget.onCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建歌单'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '输入歌单名称',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '简介',
              hintText: '输入歌单简介（可选）',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _onCreate,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
