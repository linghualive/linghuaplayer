import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../shared/widgets/cached_image.dart';
import '../player/player_controller.dart';
import 'discover_controller.dart';

class DiscoverPage extends GetView<DiscoverController> {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
      ),
      body: Obx(() {
        if (!controller.hasApiKey.value) {
          return _buildNoApiKeyState(context, theme);
        }
        return _buildMainContent(context, theme);
      }),
    );
  }

  Widget _buildNoApiKeyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI 智能推荐',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '配置 DeepSeek API Key 后，AI 将分析你的音乐偏好并推荐新歌曲',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.settings),
                  icon: const Icon(Icons.settings),
                  label: const Text('前往设置'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        controller.refreshApiKeyState();
        if (controller.preferenceTags.isNotEmpty) {
          await controller.loadRecommendations();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildTagsSection(context, theme),
          const SizedBox(height: 24),
          _buildHeartModeButton(context, theme),
          const SizedBox(height: 24),
          _buildRecommendationsSection(context, theme),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '偏好标签',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Obx(() => controller.isGeneratingTags.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: controller.generateTagsFromHistory,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI 分析'),
                  )),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.preferenceTags.isEmpty) {
            return Text(
              '暂无标签，点击「AI 分析」从历史记录生成',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...controller.preferenceTags.map((tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () => controller.removeTag(tag),
                  )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('添加'),
                onPressed: () => _showAddTagDialog(context),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeartModeButton(BuildContext context, ThemeData theme) {
    return Obx(() {
      final playerCtrl = Get.find<PlayerController>();
      final isActive = playerCtrl.isHeartMode.value;
      final isLoading = playerCtrl.isHeartModeLoading.value;

      return FilledButton.tonal(
        onPressed: !isLoading
            ? () {
                if (isActive) {
                  playerCtrl.deactivateHeartMode();
                } else {
                  controller.enterHeartMode();
                }
              }
            : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: isActive ? Colors.pink.shade100 : null,
          foregroundColor: isActive ? Colors.pink.shade700 : null,
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '正在搜索推荐歌曲...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.favorite : Icons.favorite_border,
                    color: isActive ? Colors.pink : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive
                        ? '退出心动模式'
                        : controller.preferenceTags.isNotEmpty
                            ? '进入心动模式'
                            : '随机听歌',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildRecommendationsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'AI 推荐',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Obx(() => TextButton.icon(
                  onPressed: controller.isLoadingRecommendations.value
                      ? null
                      : controller.loadRecommendations,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新推荐'),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingRecommendations.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (controller.aiRecommendedSongs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '点击「刷新推荐」获取 AI 推荐歌曲',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: controller.aiRecommendedSongs.map((video) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedImage(
                    imageUrl: video.pic,
                    width: 48,
                    height: 48,
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  video.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.playlist_add, size: 20),
                  onPressed: () {
                    final playerCtrl = Get.find<PlayerController>();
                    playerCtrl.addToQueue(video);
                  },
                  tooltip: '添加到队列',
                ),
                onTap: () {
                  final playerCtrl = Get.find<PlayerController>();
                  playerCtrl.playFromSearch(video);
                },
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: '输入标签名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty) {
                controller.addTag(tag);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
