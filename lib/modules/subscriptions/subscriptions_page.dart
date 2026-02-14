import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/cached_image.dart';
import 'subscriptions_controller.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的追番')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.folders.isEmpty) {
          return const Center(child: Text('暂无订阅'));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200) {
              controller.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: controller.loadFolders,
            child: ListView.builder(
              itemCount: controller.folders.length +
                  (controller.hasMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.folders.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.heart_broken,
                            size: 20,
                            color: Theme.of(context).colorScheme.error),
                        tooltip: '取消订阅',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('取消订阅'),
                              content: Text(
                                  '确定要取消订阅「${folder.title}」吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    controller.cancelSub(folder);
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => controller.openFolder(folder),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
