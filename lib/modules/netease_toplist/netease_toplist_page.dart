import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/cached_image.dart';
import 'netease_toplist_controller.dart';

class NeteaseToplistPage extends StatelessWidget {
  const NeteaseToplistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NeteaseToplistController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('网易云排行榜'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView.builder(
            itemCount: controller.toplists.length,
            itemBuilder: (context, index) {
              final toplist = controller.toplists[index];
              return _ToplistCard(
                toplist: toplist,
                onTap: () => Get.toNamed(
                  AppRoutes.neteasePlaylistDetail,
                  arguments: toplist.id,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _ToplistCard extends StatelessWidget {
  final NeteaseToplistItem toplist;
  final VoidCallback? onTap;

  const _ToplistCard({required this.toplist, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedImage(
              imageUrl: toplist.coverUrl,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toplist.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (toplist.updateFrequency.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      toplist.updateFrequency,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  ...toplist.trackPreviews.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
