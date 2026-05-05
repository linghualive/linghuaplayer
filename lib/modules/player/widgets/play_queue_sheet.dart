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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Text(
                  '播放队列',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(width: 6),
                Obx(() => Text(
                      '${controller.queue.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    )),
                const SizedBox(width: 4),
                Obx(() => IconButton(
                      icon: Icon(
                        _playModeIcon(controller.playMode.value),
                        size: 20,
                        color: controller.playMode.value == PlayMode.sequential
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: controller.togglePlayMode,
                      tooltip: _playModeLabel(controller.playMode.value),
                      visualDensity: VisualDensity.compact,
                    )),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    controller.clearQueue();
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.outline,
                  ),
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          // Queue list
          Flexible(
            child: Obx(() {
              if (controller.queue.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('播放队列为空'),
                );
              }
              return ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: controller.queue.length,
                onReorder: controller.reorderQueue,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final item = controller.queue[index];
                  final isCurrent = index == controller.currentIndex.value;
                  return ListTile(
                    key: ValueKey(item.video.uniqueId),
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    leading: SizedBox(
                      width: 28,
                      child: Center(
                        child: isCurrent
                            ? Icon(
                                Icons.equalizer_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              )
                            : Text(
                                '${index + 1}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      item.video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isCurrent
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                    subtitle: Text(
                      item.video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrent)
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                            ),
                            onPressed: () =>
                                controller.removeFromQueue(index),
                            visualDensity: VisualDensity.compact,
                          ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => controller.playAt(index),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _playModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
    }
  }

  String _playModeLabel(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.repeatOne:
        return '单曲循环';
    }
  }
}
