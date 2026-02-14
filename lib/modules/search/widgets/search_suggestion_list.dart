import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_controller.dart' as app;

class SearchSuggestionList extends GetView<app.SearchController> {
  const SearchSuggestionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        itemCount: controller.suggestions.length,
        itemBuilder: (context, index) {
          final item = controller.suggestions[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(item.value),
            onTap: () => controller.onSuggestionTap(item.value),
          );
        },
      );
    });
  }
}
