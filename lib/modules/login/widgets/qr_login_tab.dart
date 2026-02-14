import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../login_controller.dart';

class QrLoginTab extends GetView<LoginController> {
  const QrLoginTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan QR Code',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Use Bilibili app to scan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Obx(() {
              if (controller.qrcodeUrl.value.isEmpty) {
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
                  data: controller.qrcodeUrl.value,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              );
            }),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.qrStatus.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: controller.qrStatus.value.contains('expired')
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.qrStatus.value.contains('expired')) {
                return FilledButton.icon(
                  onPressed: controller.refreshQrcode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh QR Code'),
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
