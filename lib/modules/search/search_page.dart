import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../shared/widgets/empty_widget.dart';
import 'search_controller.dart' as app;
import 'widgets/hot_search_list.dart';
import 'widgets/search_suggestion_list.dart';
import 'widgets/search_result_card.dart';

class SearchPage extends GetView<app.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SearchBar(
            controller: controller.searchTextController,
            focusNode: controller.focusNode,
            hintText: '搜索音乐...',
            textStyle: WidgetStateProperty.all(
              Theme.of(context).textTheme.bodyLarge,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: [
              Obx(() {
                if (controller.currentKeyword.isNotEmpty ||
                    controller.searchTextController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: controller.clearSearch,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
            onSubmitted: controller.search,
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case app.SearchState.hot:
            return const HotSearchList();
          case app.SearchState.suggesting:
            return const SearchSuggestionList();
          case app.SearchState.empty:
            return const EmptyWidget(message: '未找到结果');
          case app.SearchState.results:
            return _buildResults();
        }
      }),
    );
  }

  Widget _buildResults() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          controller.loadMore();
        }
        return false;
      },
      child: Obx(() {
        if (controller.isLoading.value && controller.allResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: controller.allResults.length +
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.allResults.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final video = controller.allResults[index] as SearchVideoModel;
            return SearchResultCard(video: video);
          },
        );
      }),
    );
  }
}
