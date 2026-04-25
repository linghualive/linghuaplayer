import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_controller.dart';
import 'widgets/qr_login_tab.dart';
import 'widgets/sms_login_tab.dart';
import 'widgets/password_login_tab.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: _buildBilibiliContent(),
    );
  }

  Widget _buildBilibiliContent() {
    if (!LoginController.isMobile) {
      return const QrLoginTab();
    }
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
