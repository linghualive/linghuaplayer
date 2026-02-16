import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/platform_utils.dart';
import '../desktop/widgets/desktop_navigation_rail.dart';
import '../desktop/widgets/desktop_player_bar.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: controller.pages,
        );
      }),
      bottomNavigationBar: Obx(() {
        final currentIdx = controller.currentIndex.value;
        final isPlayerTab = currentIdx == 0;
        const labels = ['播放', '搜索', '歌单', '我的'];

        return Container(
          color: isPlayerTab ? Colors.transparent : theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 48,
              child: Row(
                children: List.generate(labels.length, (index) {
                  final isSelected = currentIdx == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => controller.onTabChanged(index),
                      child: Center(
                        child: Text(
                          labels[index],
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final extended = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // NavigationRail
                Obx(() => DesktopNavigationRail(
                      selectedIndex: controller.selectedIndex.value,
                      onDestinationSelected:
                          controller.onNavigationChanged,
                      extended: extended,
                    )),
                // Vertical divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                // Content area
                Expanded(
                  child: Obx(() {
                    return IndexedStack(
                      index: controller.selectedIndex.value,
                      children: controller.pages,
                    );
                  }),
                ),
              ],
            ),
          ),
          // Desktop player bar
          const DesktopPlayerBar(),
        ],
      ),
    );
  }
}
