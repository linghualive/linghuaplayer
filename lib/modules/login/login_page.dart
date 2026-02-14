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
        title: const Text('Login'),
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: 'QR Code'),
            Tab(text: 'SMS'),
            Tab(text: 'Password'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: const [
          QrLoginTab(),
          SmsLoginTab(),
          PasswordLoginTab(),
        ],
      ),
    );
  }
}
