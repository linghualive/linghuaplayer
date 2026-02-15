import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_controller.dart';
import 'widgets/qr_login_tab.dart';
import 'widgets/sms_login_tab.dart';
import 'widgets/password_login_tab.dart';
import 'widgets/netease_qr_login_tab.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: Column(
        children: [
          // Platform selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(() => SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('哔哩哔哩'),
                      icon: Icon(Icons.play_circle_outline),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('网易云音乐'),
                      icon: Icon(Icons.music_note_outlined),
                    ),
                  ],
                  selected: {controller.selectedPlatform.value},
                  onSelectionChanged: (selected) =>
                      controller.selectPlatform(selected.first),
                )),
          ),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.selectedPlatform.value == 0) {
                return _buildBilibiliContent();
              } else {
                return const NeteaseQrLoginTab();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBilibiliContent() {
    return Column(
      children: [
        TabBar(
          controller: controller.bilibiliTabController,
          tabs: const [
            Tab(text: '扫码登录'),
            Tab(text: '短信登录'),
            Tab(text: '密码登录'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: controller.bilibiliTabController,
            children: const [
              QrLoginTab(),
              SmsLoginTab(),
              PasswordLoginTab(),
            ],
          ),
        ),
      ],
    );
  }
}
