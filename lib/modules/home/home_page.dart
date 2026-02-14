import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/player/widgets/mini_player_bar.dart';
import '../../modules/search/search_page.dart';
import '../../modules/search/search_controller.dart' as app;
import '../../modules/profile/profile_page.dart';
import '../../modules/profile/profile_controller.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sub-controllers are created
    Get.put(app.SearchController());
    Get.put(ProfileController());

    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            SearchPage(),
            ProfilePage(),
          ],
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
                    icon: Icon(Icons.search),
                    selectedIcon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
