import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

class PlayQueueSheet extends GetView<PlayerController> {
  const PlayQueueSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const PlayQueueSheet(),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Obx(() => Text(
                      '播放队列 (${controller.queue.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    controller.clearQueue();
                    Get.back();
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Queue list
          Flexible(
            child: Obx(() {
              if (controller.queue.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('播放队列为空'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.queue.length,
                itemBuilder: (context, index) {
                  final item = controller.queue[index];
                  final isCurrent = index == controller.currentIndex.value;
                  return ListTile(
                    leading: isCurrent
                        ? Icon(
                            Icons.music_note,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                    title: Text(
                      item.video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isCurrent
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                    subtitle: Text(
                      item.video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                controller.removeFromQueue(index),
                          ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
