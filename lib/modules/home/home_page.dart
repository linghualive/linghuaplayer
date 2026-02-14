import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/player/widgets/mini_player_bar.dart';
import '../../modules/profile/profile_page.dart';
import '../../modules/profile/profile_controller.dart';
import '../../modules/recommend/recommend_page.dart';
import '../../modules/recommend/recommend_controller.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure sub-controllers are created
    Get.put(RecommendController());
    Get.put(ProfileController());

    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            RecommendPage(),
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
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '首页',
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
}
