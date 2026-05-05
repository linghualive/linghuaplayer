import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';
import '../services/audio_output_service.dart';

class AudioOutputSheet extends GetView<PlayerController> {
  const AudioOutputSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const AudioOutputSheet(),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '音频输出',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => controller.audioOutput.showOutputPicker(),
                  tooltip: '刷新设备列表',
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          // Device list
          Flexible(
            child: Obx(() {
              final deviceList = controller.audioOutput.devices;
              if (deviceList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('未检测到音频设备'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: deviceList.length,
                itemBuilder: (context, index) {
                  final device = deviceList[index];
                  return ListTile(
                    leading: Icon(
                      _iconForType(device.type),
                      color: device.isActive
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: device.isActive
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                    trailing: device.isActive
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      controller.audioOutput.selectDevice(device.id);
                      Get.back();
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(AudioOutputType type) {
    switch (type) {
      case AudioOutputType.speaker:
        return Icons.speaker;
      case AudioOutputType.bluetooth:
        return Icons.bluetooth_audio;
      case AudioOutputType.wired:
        return Icons.headphones;
      case AudioOutputType.airplay:
        return Icons.airplay;
      case AudioOutputType.usb:
        return Icons.usb;
      case AudioOutputType.hdmi:
        return Icons.settings_input_hdmi;
      case AudioOutputType.unknown:
        return Icons.volume_up;
    }
  }
}
