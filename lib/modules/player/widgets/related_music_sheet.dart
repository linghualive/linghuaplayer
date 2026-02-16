import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/utils/app_toast.dart';
import '../player_controller.dart';

class RelatedMusicSheet extends GetView<PlayerController> {
  const RelatedMusicSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const RelatedMusicSheet(),
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
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
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
                      '相关推荐 (${controller.relatedMusic.length})',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    )),
                const Spacer(),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: Obx(() {
              if (controller.relatedMusicLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.relatedMusic.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('暂无相关推荐')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.relatedMusic.length,
                itemBuilder: (context, index) {
                  final song = controller.relatedMusic[index];
                  return ListTile(
                    leading: song.pic.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.pic.startsWith('//')
                                  ? 'https:${song.pic}'
                                  : song.pic,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 24),
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note, size: 24),
                          ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${song.author}  ${song.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.playlist_add, size: 20),
                      tooltip: '添加到播放列表',
                      onPressed: () async {
                        final success =
                            await controller.addToQueueSilent(song);
                        if (success) {
                          AppToast.show('已添加到播放列表');
                        } else {
                          AppToast.show('已在播放列表中');
                        }
                      },
                    ),
                    onTap: () {
                      Get.back();
                      controller.playFromSearch(song);
                    },
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
