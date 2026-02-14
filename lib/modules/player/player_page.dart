import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_controls.dart';
import 'widgets/play_queue_sheet.dart';

class PlayerPage extends GetView<PlayerController> {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: PlayQueueSheet.show,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.currentVideo.value == null) {
            return const Center(child: Text('No track selected'));
          }

          return Column(
            children: [
              const Spacer(flex: 1),
              const PlayerArtwork(),
              const Spacer(flex: 2),
              const PlayerControls(),
              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }
}
