import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../login_controller.dart';

class NeteaseQrLoginTab extends GetView<LoginController> {
  const NeteaseQrLoginTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '网易云扫码登录',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '请使用网易云音乐客户端扫码',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              if (controller.neteaseQrUrl.value.isEmpty) {
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
                child: QrImageView(
                  data: controller.neteaseQrUrl.value,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              );
            }),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.neteaseQrStatus.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: controller.neteaseQrStatus.value.contains('过期')
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.neteaseQrStatus.value.contains('过期')) {
                return FilledButton.icon(
                  onPressed: controller.refreshNeteaseQrcode,
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
