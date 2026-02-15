import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_controller.dart';
import '../../shared/responsive/adaptive_scaffold.dart';
import '../../shared/responsive/breakpoints.dart';
import 'widgets/desktop_navigation_rail.dart';
import 'widgets/desktop_player_bar.dart';

/// Desktop home scaffold that provides the main structure for desktop layout
class DesktopHomeScaffold extends GetView<HomeController> {
  const DesktopHomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = Breakpoints.getWindowSizeClass(constraints.maxWidth);
        final isLarge = sizeClass == WindowSizeClass.large;

        return AdaptiveScaffold(
          body: Obx(() {
            // Get current page based on selected index
            return controller.currentPage;
          }),
          navigationRail: Obx(() => DesktopNavigationRail(
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: controller.onNavigationChanged,
            extended: isLarge,
          )),
          bottomBar: const DesktopPlayerBar(),
          backgroundColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }
}