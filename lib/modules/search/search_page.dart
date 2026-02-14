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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SearchBar(
            controller: controller.searchTextController,
            focusNode: controller.focusNode,
            hintText: 'Search music...',
            leading: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.search),
            ),
            trailing: [
              Obx(() {
                if (controller.currentKeyword.isNotEmpty ||
                    controller.searchTextController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.clearSearch,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
            onSubmitted: controller.search,
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
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
            return const EmptyWidget(message: 'No results found');
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
          itemCount:
              controller.allResults.length + (controller.isLoadingMore.value ? 1 : 0),
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
