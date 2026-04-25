import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/platform_utils.dart';
import '../desktop/widgets/desktop_navigation_rail.dart';
import '../desktop/widgets/desktop_player_bar.dart';
import '../player/player_home_tab.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop) {
      return _buildDesktopLayout(context);
    }
    return const PlayerHomeTab();
  }

  Widget _buildDesktopLayout(BuildContext context) {
    const extended = true;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Obx(() => DesktopNavigationRail(
                      selectedIndex: controller.selectedIndex.value,
                      onDestinationSelected:
                          controller.onNavigationChanged,
                      extended: extended,
                    )),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
          const DesktopPlayerBar(),
        ],
      ),
    );
  }
}
