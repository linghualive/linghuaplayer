import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_controller.dart' as app;

class HotSearchList extends GetView<app.SearchController> {
  const HotSearchList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.hotSearchList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hot Search',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.hotSearchList.map((item) {
              return ActionChip(
                label: Text(item.showName),
                onPressed: () => controller.onHotKeywordTap(item.keyword),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
