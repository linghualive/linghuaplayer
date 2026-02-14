import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'player_controller.dart';

class FullScreenVideoPage extends StatefulWidget {
  const FullScreenVideoPage({super.key});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  final controller = Get.find<PlayerController>();
  bool _showControls = true;

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _exit() {
    controller.exitFullScreen();
    Get.back();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final videoCtrl = controller.videoController;
    if (videoCtrl == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No video', style: TextStyle(color: Colors.white))),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          controller.exitFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Video fills screen
              Center(
                child: Video(
                  controller: videoCtrl,
                  controls: NoVideoControls,
                  fit: BoxFit.contain,
                ),
              ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // Semi-transparent background
                      Container(color: Colors.black38),

                      // Exit fullscreen button (top-left)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.fullscreen_exit,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _exit,
                        ),
                      ),

                      // Play/pause (center)
                      Center(
                        child: Obx(() => IconButton(
                              iconSize: 56,
                              icon: Icon(
                                controller.isPlaying.value
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: controller.togglePlay,
                            )),
                      ),

                      // Seek bar + time labels (bottom)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        child: Obx(() {
                          final pos = controller.position.value;
                          final dur = controller.duration.value;
                          final maxMs = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                          final currentMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: const SliderThemeData(
                                  trackHeight: 3,
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 14),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: currentMs,
                                  max: maxMs,
                                  onChanged: (value) {
                                    controller.seekTo(
                                        Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(pos),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(dur),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
