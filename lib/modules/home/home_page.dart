import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/player/widgets/mini_player_bar.dart';
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
    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: controller.pages,
        );
      }),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          Obx(() => NavigationBar(
                selectedIndex: controller.currentIndex.value,
                onDestinationSelected: controller.onTabChanged,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.music_note_outlined),
                    selectedIcon: Icon(Icons.music_note),
                    label: '音乐',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.queue_music_outlined),
                    selectedIcon: Icon(Icons.queue_music),
                    label: '歌单',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: '我的',
                  ),
                ],
              )),
        ],
      ),
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
