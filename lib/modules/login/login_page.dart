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
        bottom: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '扫码登录'),
            Tab(text: '短信登录'),
            Tab(text: '密码登录'),
            Tab(text: '网易云扫码'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: const [
          QrLoginTab(),
          SmsLoginTab(),
          PasswordLoginTab(),
          NeteaseQrLoginTab(),
        ],
      ),
    );
  }
}
