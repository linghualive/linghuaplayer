import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_controller.dart' as app;
import 'search_skeleton.dart';

class HotSearchList extends GetView<app.SearchController> {
  const HotSearchList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.hotSearchList.isEmpty) {
        return const HotSearchSkeleton();
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Search history
          if (controller.searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '搜索历史',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                TextButton(
                  onPressed: controller.clearHistory,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '清空',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.searchHistory.map((keyword) {
                return InputChip(
                  label: Text(keyword),
                  onPressed: () => controller.onHotKeywordTap(keyword),
                  onDeleted: () => controller.removeHistory(keyword),
                  deleteIconColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Hot search
          Text(
            '热门搜索',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.hotSearchList.map((item) {
              return ActionChip(
                label: Text(item.showName),
                onPressed: () => controller.onHotKeywordTap(item.keyword),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),

          // 热门歌手
          const SizedBox(height: 24),
          Text(
            '热门歌手',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: app.SearchController.hotArtists.map((artist) {
              return ActionChip(
                label: Text(artist),
                onPressed: () => controller.onHotKeywordTap(artist),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),

        ],
      );
    });
  }
}
