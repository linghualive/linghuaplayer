import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/user/fav_folder_model.dart';
import '../../data/repositories/user_repository.dart';
import 'create_fav_dialog.dart';

class FavPanel extends StatefulWidget {
  final int aid;

  const FavPanel({super.key, required this.aid});

  @override
  State<FavPanel> createState() => _FavPanelState();

  static void show(BuildContext context, int aid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FavPanel(aid: aid),
    );
  }
}

class _FavPanelState extends State<FavPanel> {
  final _repo = Get.find<UserRepository>();
  List<FavFolderModel> _folders = [];
  late Map<int, bool> _checked;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checked = {};
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final storage = Get.find<StorageService>();
    final mid = storage.userMid;
    if (mid == null) {
      setState(() => _loading = false);
      return;
    }
    final folders =
        await _repo.getFavFoldersAll(upMid: int.parse(mid), rid: widget.aid);
    setState(() {
      _folders = folders;
      _checked = {
        for (final f in folders) f.id: f.favState == 1,
      };
      _loading = false;
    });
  }

  Future<void> _onConfirm() async {
    final addIds = <int>[];
    final delIds = <int>[];
    for (final f in _folders) {
      final wasChecked = f.favState == 1;
      final isChecked = _checked[f.id] ?? false;
      if (isChecked && !wasChecked) {
        addIds.add(f.id);
      } else if (!isChecked && wasChecked) {
        delIds.add(f.id);
      }
    }
    if (addIds.isEmpty && delIds.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final ok = await _repo.favResourceDeal(
      rid: widget.aid,
      addIds: addIds,
      delIds: delIds,
    );
    if (mounted) Navigator.pop(context);
    if (ok) {
      Get.snackbar('提示', '收藏成功', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('错误', '操作失败', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  '收藏到',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    CreateFavDialog.show(context, onCreated: _loadFolders);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建'),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_folders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无收藏夹'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  return CheckboxListTile(
                    title: Text(folder.title),
                    subtitle: Text('${folder.mediaCount}个内容'),
                    value: _checked[folder.id] ?? false,
                    onChanged: (val) {
                      setState(() => _checked[folder.id] = val ?? false);
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    onPressed: _loading ? null : _onConfirm,
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
