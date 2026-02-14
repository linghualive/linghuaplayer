import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/cached_image.dart';
import 'favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.folders.isEmpty) {
          return const Center(child: Text('暂无收藏'));
        }
        return RefreshIndicator(
          onRefresh: controller.loadFolders,
          child: ListView.builder(
            itemCount: controller.folders.length,
            itemBuilder: (context, index) {
              final folder = controller.folders[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedImage(
                    imageUrl: folder.cover,
                    width: 60,
                    height: 40,
                  ),
                ),
                title: Text(
                  folder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${folder.mediaCount} 个内容'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => controller.openFolder(folder),
              );
            },
          ),
        );
      }),
    );
  }
}
