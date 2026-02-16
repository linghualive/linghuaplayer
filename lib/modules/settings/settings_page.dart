import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/color_type.dart';
import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // ── 外观设置 ──
          _buildSectionHeader(theme, '外观设置'),

          // Theme Mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '主题模式',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Obx(() => RadioGroup<int>(
                groupValue: controller.themeCtrl.themeMode.value,
                onChanged: (v) {
                  if (v != null) controller.themeCtrl.setThemeMode(v);
                },
                child: Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('跟随系统'),
                      value: 0,
                    ),
                    RadioListTile<int>(
                      title: const Text('浅色'),
                      value: 1,
                    ),
                    RadioListTile<int>(
                      title: const Text('深色'),
                      value: 2,
                    ),
                  ],
                ),
              )),

          // Dynamic Color
          Obx(() => SwitchListTile(
                title: const Text('动态取色 (Monet)'),
                subtitle: const Text('使用壁纸颜色'),
                value: controller.themeCtrl.dynamicColor.value,
                onChanged: (v) => controller.themeCtrl.setDynamicColor(v),
              )),

          // Color Palette
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '主题色',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final selected = controller.themeCtrl.customColorIndex.value;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  colorThemeTypes.length - 1,
                  (i) {
                    final index = i + 1;
                    final ct = colorThemeTypes[index];
                    final isSelected = selected == index;
                    return GestureDetector(
                      onTap: () => controller.themeCtrl.setCustomColor(index),
                      child: Tooltip(
                        message: ct.label,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ct.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // ── 播放设置 ──
          _buildSectionHeader(theme, '播放设置'),

          // Video Playback
          Obx(() => SwitchListTile(
                title: const Text('默认视频模式'),
                subtitle: const Text('开启后默认播放视频画面，可在播放页切换'),
                value: controller.enableVideo.value,
                onChanged: (v) => controller.setEnableVideo(v),
              )),

          const Divider(),

          // ── AI 智能推荐 ──
          _buildSectionHeader(theme, 'AI 智能推荐'),

          Obx(() => ListTile(
                leading: const Icon(Icons.key),
                title: const Text('DeepSeek API Key'),
                subtitle: Text(
                  controller.deepseekApiKey.value.isNotEmpty
                      ? '已配置 (${controller.deepseekApiKey.value.substring(0, 8)}...)'
                      : '未配置',
                  style: TextStyle(
                    color: controller.deepseekApiKey.value.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                trailing: controller.isValidatingKey.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: controller.isValidatingKey.value
                    ? null
                    : () => _showApiKeyDialog(context),
              )),

          const Divider(),

          // ── 关于 ──
          _buildSectionHeader(theme, '关于'),

          Obx(() => ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('检查更新'),
                subtitle: controller.appVersion.value.isNotEmpty
                    ? Text('当前版本: ${controller.appVersion.value}')
                    : null,
                trailing: Obx(() => controller.isCheckingUpdate.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right)),
                onTap: controller.isCheckingUpdate.value
                    ? null
                    : controller.checkForUpdate,
              )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final textController = TextEditingController(
      text: controller.deepseekApiKey.value,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DeepSeek API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: '输入 API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              '用于 AI 分析音乐偏好和推荐歌曲',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        actions: [
          if (controller.deepseekApiKey.value.isNotEmpty)
            TextButton(
              onPressed: () {
                controller.clearDeepseekApiKey();
                Navigator.of(ctx).pop();
              },
              child: const Text('清除'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final key = textController.text.trim();
              Navigator.of(ctx).pop();
              if (key.isNotEmpty) {
                final success = await controller.setDeepseekApiKey(key);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key 验证失败，请检查密钥')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
