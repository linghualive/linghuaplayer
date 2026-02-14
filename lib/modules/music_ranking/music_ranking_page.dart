import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/duration_formatter.dart';
import 'music_ranking_controller.dart';

class MusicRankingPage extends StatelessWidget {
  const MusicRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicRankingController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐排行榜'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Obx(() {
            if (controller.periods.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.periods.length,
                itemBuilder: (context, index) {
                  final period = controller.periods[index];
                  final isSelected =
                      index == controller.selectedPeriodIndex.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(period.name),
                      selected: isSelected,
                      onSelected: (_) => controller.selectPeriod(index),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.songs.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: controller.songs.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.songs.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final song = controller.songs[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${song.rank}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: song.rank <= 3
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: song.cover,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 48,
                          height: 48,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.music_note, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                trailing: Text(
                  DurationFormatter.format(song.duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                onTap: () => controller.playSong(song),
              );
            },
          ),
        );
      }),
    );
  }
}
