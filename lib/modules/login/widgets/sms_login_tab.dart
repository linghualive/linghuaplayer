import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../login_controller.dart';

class SmsLoginTab extends GetView<LoginController> {
  const SmsLoginTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'SMS Login',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixText: '+86 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.smsCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'SMS Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                final countdown = controller.smsCountdown.value;
                return SizedBox(
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: countdown > 0 ? null : controller.sendSmsCode,
                    child: Text(
                      countdown > 0 ? '${countdown}s' : 'Send Code',
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 32),
          Obx(() => FilledButton(
                onPressed:
                    controller.isLoading.value ? null : controller.submitSmsCode,
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              )),
        ],
      ),
    );
  }
}
