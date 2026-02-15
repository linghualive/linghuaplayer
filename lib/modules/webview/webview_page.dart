import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../shared/utils/app_toast.dart';
import '../home/home_controller.dart';

/// A general-purpose WebView page.
///
/// Pass arguments via [Get.arguments] as a `Map<String, String>`:
/// - `url`       – the URL to load (required)
/// - `title`     – page title shown in the AppBar
/// - `type`      – `"login"` to enable login-success detection
class WebviewPage extends StatefulWidget {
  const WebviewPage({super.key});

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  late final WebViewController _controller;
  final _progress = 0.0.obs;
  final _loading = true.obs;

  late final String _url;
  late final String _title;
  late final String _type;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, String>? ?? {};
    _url = args['url'] ?? '';
    _title = args['title'] ?? '';
    _type = args['type'] ?? 'url';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          _progress.value = progress / 100;
        },
        onPageStarted: (_) {
          _loading.value = true;
        },
        onPageFinished: (_) {
          _loading.value = false;
        },
        onUrlChange: (change) {
          final url = change.url ?? '';
          if (_type == 'login' && _isLoginSuccessUrl(url)) {
            _onLoginSuccess();
          }
        },
      ));

    if (_type == 'login') {
      _controller.clearCache();
      _controller.clearLocalStorage();
      WebViewCookieManager().clearCookies();
    }

    if (_url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(_url));
    }
  }

  bool _isLoginSuccessUrl(String url) {
    return url.startsWith(
            'https://passport.bilibili.com/web/sso/exchange_cookie') ||
        url.startsWith('https://m.bilibili.com/');
  }

  Future<void> _onLoginSuccess() async {
    // The password login API already set session cookies in Dio's cookie jar.
    // The WebView verification just confirms the device on the server side.
    // Calling confirmLogin() will use the existing session to fetch user info.
    final authRepo = Get.find<AuthRepository>();
    final success = await authRepo.confirmLogin();

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshLoginStatus();
    }

    Get.back();
    AppToast.success(success ? '登录成功' : '登录成功，但获取用户信息失败');
  }

  Future<void> _manualRefreshLogin() async {
    final authRepo = Get.find<AuthRepository>();
    final success = await authRepo.confirmLogin();
    if (success) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshLoginStatus();
      }
      Get.back();
      AppToast.success('登录成功');
    } else {
      AppToast.show('暂未检测到登录状态');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_type == 'login')
            TextButton(
              onPressed: _manualRefreshLogin,
              child: const Text('刷新登录状态'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (!_loading.value) return const SizedBox.shrink();
            return LinearProgressIndicator(value: _progress.value);
          }),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
