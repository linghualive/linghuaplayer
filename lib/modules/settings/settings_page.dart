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
          // Theme Mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

          const Divider(),

          // Dynamic Color
          Obx(() => SwitchListTile(
                title: const Text('动态取色 (Monet)'),
                subtitle: const Text('使用壁纸颜色'),
                value: controller.themeCtrl.dynamicColor.value,
                onChanged: (v) => controller.themeCtrl.setDynamicColor(v),
              )),

          const Divider(),

          // Video Playback
          Obx(() => SwitchListTile(
                title: const Text('视频播放'),
                subtitle: const Text('开启后播放视频画面，关闭为纯音频模式'),
                value: controller.enableVideo.value,
                onChanged: (v) => controller.setEnableVideo(v),
              )),

          const Divider(),

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
              // Skip index 0 (Dynamic) — that's controlled by the switch
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

          // Grid Columns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '列数',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() => Row(
                  children: [1, 2, 3].map((cols) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$cols'),
                        selected: controller.gridColumns.value == cols,
                        onSelected: (_) => controller.setGridColumns(cols),
                      ),
                    );
                  }).toList(),
                )),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
