import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../login_controller.dart';

class QqMusicQrLoginTab extends GetView<LoginController> {
  const QqMusicQrLoginTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QQ音乐扫码登录',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '请使用QQ客户端扫码',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              final imageBytes = controller.qqMusicQrImage.value;
              if (imageBytes == null) {
                return const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.memory(
                  imageBytes,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              );
            }),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.qqMusicQrStatus.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: controller.qqMusicQrStatus.value.contains('过期')
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.qqMusicQrStatus.value.contains('过期') ||
                  controller.qqMusicQrStatus.value.contains('失败')) {
                return FilledButton.icon(
                  onPressed: controller.refreshQqMusicQrcode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新二维码'),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
