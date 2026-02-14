import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../shared/widgets/loading_widget.dart';
import 'recommend_controller.dart';
import 'widgets/video_card_v.dart';

class RecommendPage extends StatelessWidget {
  const RecommendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecommendController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.search),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(19),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.videoList.isEmpty) {
          return const LoadingWidget();
        }

        return RefreshIndicator(
          onRefresh: controller.loadFeed,
          child: Obx(() {
            final columns = controller.crossAxisCount.value;
            final screenWidth = MediaQuery.of(context).size.width;
            final padding = 12.0;
            final spacing = 8.0;
            final itemWidth =
                (screenWidth - padding * 2 - spacing * (columns - 1)) /
                    columns;
            final thumbnailHeight = itemWidth / (16 / 10);
            final infoHeight = 58.0;
            final itemHeight = thumbnailHeight + infoHeight;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == controller.videoList.length) {
                          // Load more trigger
                          controller.loadMore();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final video = controller.videoList[index];
                        return VideoCardV(
                          video: video,
                          onTap: () => controller.onVideoTap(video),
                        );
                      },
                      childCount: controller.videoList.length + 1,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      mainAxisExtent: itemHeight,
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      }),
    );
  }
}
