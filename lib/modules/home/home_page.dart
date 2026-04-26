import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player/player_home_tab.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayerHomeTab();
  }
}
