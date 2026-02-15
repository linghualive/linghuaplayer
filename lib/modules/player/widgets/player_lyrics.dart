import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

class PlayerLyrics extends GetView<PlayerController> {
  const PlayerLyrics({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final theme = Theme.of(context);

    return Obx(() {
      final lyrics = controller.lyrics.value;
      final isLoading = controller.lyricsLoading.value;

      // Still loading
      if (isLoading && lyrics == null) {
        return const Center(
          child: Text(
            '歌词加载中...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Finished loading, no lyrics found
      if (lyrics == null) {
        return const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Plain lyrics only (no sync)
      if (!lyrics.hasSyncedLyrics) {
        if (lyrics.plainLyrics != null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              lyrics.plainLyrics!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 2.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );
        }
        return const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Synced lyrics
      final currentIndex = controller.currentLyricsIndex.value;
      final lines = lyrics.lines;

      // Auto-scroll to current line
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentIndex >= 0 && scrollController.hasClients) {
          final targetOffset = currentIndex * 48.0 -
              scrollController.position.viewportDimension / 2 +
              24;
          scrollController.animateTo(
            targetOffset.clamp(
              0.0,
              scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        itemCount: lines.length,
        itemExtent: 48,
        itemBuilder: (context, index) {
          final line = lines[index];
          final isCurrent = index == currentIndex;
          final isPast = index < currentIndex;

          return GestureDetector(
            onTap: () => controller.seekTo(line.timestamp),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCurrent ? 18 : 15,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : isPast
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
