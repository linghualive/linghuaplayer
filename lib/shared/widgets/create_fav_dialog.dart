import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repositories/user_repository.dart';
import '../../modules/playlist/playlist_controller.dart';

class CreateFavDialog extends StatefulWidget {
  /// Optional callback after folder is created successfully.
  /// Used by FavPanel to refresh its folder list.
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
  final _introController = TextEditingController();
  bool _isPrivate = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('提示', '请输入收藏夹名称',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submitting = true);

    final repo = Get.find<UserRepository>();
    final ok = await repo.addFavFolder(
      title: title,
      intro: _introController.text.trim(),
      privacy: _isPrivate ? 1 : 0,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      Get.snackbar('提示', '创建成功', snackPosition: SnackPosition.BOTTOM);

      // Refresh playlist page if it's registered
      if (Get.isRegistered<PlaylistController>()) {
        Get.find<PlaylistController>().loadFolders();
      }

      widget.onCreated?.call();
    } else {
      setState(() => _submitting = false);
      Get.snackbar('错误', '创建失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建收藏夹'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '输入收藏夹名称',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _introController,
            decoration: const InputDecoration(
              labelText: '简介',
              hintText: '输入收藏夹简介（可选）',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('设为私密'),
            contentPadding: EdgeInsets.zero,
            value: _isPrivate,
            onChanged: (val) => setState(() => _isPrivate = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _onCreate,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }
}
