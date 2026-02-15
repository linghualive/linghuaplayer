import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gt3_flutter_plugin/gt3_flutter_plugin.dart';

import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/login/captcha_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/music_discovery/music_discovery_controller.dart';
import '../../modules/playlist/playlist_controller.dart';
import '../../shared/utils/app_toast.dart';

class LoginController extends GetxController with GetTickerProviderStateMixin {
  late final TabController bilibiliTabController;
  final _authRepo = Get.find<AuthRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _storage = Get.find<StorageService>();

  // GeeTest plugin instance
  final Gt3FlutterPlugin _captcha = Gt3FlutterPlugin();

  // Platform selection: 0 = Bilibili, 1 = NetEase
  final selectedPlatform = 0.obs;

  // Bilibili QR Login
  final qrcodeUrl = ''.obs;
  final qrcodeKey = ''.obs;
  final qrStatus = ''.obs;
  Timer? _qrPollTimer;
  int _qrPollCount = 0;

  // NetEase QR Login
  final neteaseQrUrl = ''.obs;
  final neteaseQrKey = ''.obs;
  final neteaseQrStatus = ''.obs;
  Timer? _neteaseQrPollTimer;
  int _neteaseQrPollCount = 0;

  // SMS Login
  final phoneController = TextEditingController();
  final smsCodeController = TextEditingController();
  final countryCode = 86.obs;
  final smsCountdown = 0.obs;
  final captchaKey = ''.obs;
  Timer? _smsTimer;

  // Password Login
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;

  // Common
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    bilibiliTabController = TabController(length: 3, vsync: this);
    bilibiliTabController.addListener(_onBilibiliTabChanged);
    _generateQrcode();
  }

  @override
  void onClose() {
    bilibiliTabController.dispose();
    _qrPollTimer?.cancel();
    _neteaseQrPollTimer?.cancel();
    _smsTimer?.cancel();
    phoneController.dispose();
    smsCodeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void selectPlatform(int index) {
    if (selectedPlatform.value == index) return;
    selectedPlatform.value = index;

    // Stop all polling when switching platforms
    _qrPollTimer?.cancel();
    _neteaseQrPollTimer?.cancel();

    if (index == 0) {
      // Bilibili selected - start QR if on QR tab
      if (bilibiliTabController.index == 0) {
        _generateQrcode();
      }
    } else {
      // NetEase selected
      _generateNeteaseQrcode();
    }
  }

  void _onBilibiliTabChanged() {
    if (bilibiliTabController.indexIsChanging) return;
    if (selectedPlatform.value != 0) return;

    if (bilibiliTabController.index == 0) {
      _generateQrcode();
    } else {
      _qrPollTimer?.cancel();
    }
  }

  // ── Bilibili QR Login ────────────────────────────────

  Future<void> _generateQrcode() async {
    qrStatus.value = '正在加载二维码...';
    final qrcode = await _authRepo.getQrcode();
    if (qrcode != null) {
      qrcodeUrl.value = qrcode.url ?? '';
      qrcodeKey.value = qrcode.qrcodeKey ?? '';
      qrStatus.value = '请使用哔哩哔哩客户端扫码';
      _startQrPolling();
    } else {
      qrStatus.value = '二维码生成失败';
    }
  }

  void _startQrPolling() {
    _qrPollCount = 0;
    _qrPollTimer?.cancel();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _qrPollCount++;
      if (_qrPollCount > 180) {
        timer.cancel();
        qrStatus.value = '二维码已过期';
        return;
      }
      if (qrcodeKey.value.isEmpty) return;

      final result = await _authRepo.pollQrcode(qrcodeKey.value);
      if (result.isSuccess) {
        timer.cancel();
        qrStatus.value = '登录成功！';
        await _onLoginSuccess();
      } else if (result.isScanned) {
        qrStatus.value = '已扫码，请在手机上确认';
      } else if (result.isExpired) {
        timer.cancel();
        qrStatus.value = '二维码已过期';
      }
    });
  }

  void refreshQrcode() {
    _generateQrcode();
  }

  // ── NetEase QR Login ─────────────────────────────────

  Future<void> _generateNeteaseQrcode() async {
    neteaseQrStatus.value = '正在加载二维码...';
    log('NetEase QR: generating unikey...');
    final unikey = await _neteaseRepo.getQrKey();
    log('NetEase QR: unikey=${unikey != null ? '${unikey.substring(0, unikey.length > 20 ? 20 : unikey.length)}...' : 'null'}');
    if (unikey != null) {
      neteaseQrKey.value = unikey;
      neteaseQrUrl.value = _neteaseRepo.buildQrUrl(unikey);
      neteaseQrStatus.value = '请使用网易云音乐客户端扫码';
      _startNeteaseQrPolling();
    } else {
      neteaseQrStatus.value = '二维码生成失败';
    }
  }

  void _startNeteaseQrPolling() {
    _neteaseQrPollCount = 0;
    _neteaseQrPollTimer?.cancel();
    _neteaseQrPollTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      _neteaseQrPollCount++;
      if (_neteaseQrPollCount > 150) {
        timer.cancel();
        neteaseQrStatus.value = '二维码已过期';
        return;
      }
      if (neteaseQrKey.value.isEmpty) return;

      final result = await _neteaseRepo.pollQrLogin(neteaseQrKey.value);
      log('NetEase QR poll: code=${result.code}, msg=${result.message}');
      if (result.isSuccess) {
        timer.cancel();
        neteaseQrStatus.value = '登录成功！';
        await _onNeteaseLoginSuccess();
      } else if (result.isScanned) {
        neteaseQrStatus.value = '已扫码，请在手机上确认';
      } else if (result.isExpired) {
        timer.cancel();
        neteaseQrStatus.value = '二维码已过期';
      }
    });
  }

  void refreshNeteaseQrcode() {
    _generateNeteaseQrcode();
  }

  Future<void> _onNeteaseLoginSuccess() async {
    try {
      log('NetEase QR: login success, fetching account info...');
      final userInfo = await _neteaseRepo.getAccountInfo();
      log('NetEase QR: account info=${userInfo != null ? 'uid=${userInfo.userId}, name=${userInfo.nickname}' : 'null'}');
      if (userInfo != null) {
        _storage.isNeteaseLoggedIn = true;
        _storage.neteaseUserId = userInfo.userId.toString();
        _storage.setNeteaseUserInfo(userInfo.toJson());
      } else {
        _storage.isNeteaseLoggedIn = true;
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshLoginStatus();
      }
      if (Get.isRegistered<MusicDiscoveryController>()) {
        Get.find<MusicDiscoveryController>().loadAll();
      }
      Get.back();
      AppToast.success(userInfo != null ? '网易云登录成功' : '网易云登录成功，但获取用户信息失败');
    } catch (e) {
      log('NetEase QR: _onNeteaseLoginSuccess error: $e');
      AppToast.error('登录后处理失败: $e');
    }
  }

  // ── GeeTest Captcha ──────────────────────────────────

  /// Request GeeTest captcha and show the native verification UI.
  /// On success, [onComplete] is called with the validated [CaptchaModel].
  Future<void> _getCaptchaAndDo(
      Future<void> Function(CaptchaModel) onComplete) async {
    isLoading.value = true;

    final captchaData = await _authRepo.getCaptcha();
    if (captchaData == null) {
      isLoading.value = false;
      AppToast.error('获取验证码失败');
      return;
    }

    final registerData = Gt3RegisterData(
      challenge: captchaData.geetest?.challenge,
      gt: captchaData.geetest?.gt ?? '',
      success: true,
    );

    _captcha.addEventHandler(
      onShow: (Map<String, dynamic> message) async {
        isLoading.value = false;
      },
      onClose: (Map<String, dynamic> message) async {
        isLoading.value = false;
      },
      onResult: (Map<String, dynamic> message) async {
        final code = message['code'] as String?;
        if (code == '1') {
          // Verification succeeded
          captchaData.validate =
              message['result']['geetest_validate'] as String?;
          captchaData.seccode =
              message['result']['geetest_seccode'] as String?;
          captchaData.challenge =
              message['result']['geetest_challenge'] as String?;
          await onComplete(captchaData);
        }
      },
      onError: (Map<String, dynamic> message) async {
        isLoading.value = false;
        final code = message['code']?.toString() ?? '';
        log('GeeTest error: code=$code');
        _handleGeeTestError(code);
      },
    );

    _captcha.startCaptcha(registerData);
  }

  void _handleGeeTestError(String code) {
    String msg;
    if (Platform.isAndroid) {
      switch (code) {
        case '201':
          msg = '网络无法访问';
        case '204':
          msg = '验证加载超时';
        case '204_1':
          msg = '验证页面加载错误';
        case '204_2':
          msg = 'SSL 错误';
        default:
          msg = '验证失败 ($code)';
      }
    } else if (Platform.isIOS) {
      switch (code) {
        case '-1009':
          msg = '网络无法访问';
        case '-1001':
          msg = '网络超时';
        case '-999':
          msg = '验证已取消';
        default:
          msg = '验证失败 ($code)';
      }
    } else {
      msg = '验证失败 ($code)';
    }
    AppToast.error(msg);
  }

  // ── SMS Login ───────────────────────────────────────

  Future<void> sendSmsCode() async {
    if (phoneController.text.isEmpty) {
      AppToast.error('请输入手机号');
      return;
    }

    await _getCaptchaAndDo((captchaData) async {
      final key = await _authRepo.sendSmsCode(
        cid: countryCode.value,
        tel: int.parse(phoneController.text),
        captcha: captchaData,
      );

      if (key != null) {
        captchaKey.value = key;
        _startSmsCountdown();
        AppToast.success('验证码已发送');
      } else {
        AppToast.error('验证码发送失败');
      }
    });
  }

  void _startSmsCountdown() {
    smsCountdown.value = 60;
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      smsCountdown.value--;
      if (smsCountdown.value <= 0) timer.cancel();
    });
  }

  Future<void> submitSmsCode() async {
    if (smsCodeController.text.isEmpty || captchaKey.isEmpty) return;
    isLoading.value = true;

    final success = await _authRepo.loginBySms(
      cid: countryCode.value,
      tel: int.parse(phoneController.text),
      code: int.parse(smsCodeController.text),
      captchaKey: captchaKey.value,
    );

    isLoading.value = false;
    if (success) {
      _onLoginSuccess();
    } else {
      AppToast.error('短信登录失败');
    }
  }

  // ── Password Login ──────────────────────────────────

  Future<void> loginByPassword() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      AppToast.error('请填写所有字段');
      return;
    }

    await _getCaptchaAndDo((captchaData) async {
      isLoading.value = true;

      final result = await _authRepo.loginByPassword(
        username: usernameController.text,
        password: passwordController.text,
        captcha: captchaData,
      );

      isLoading.value = false;

      if (result.success) {
        await _onLoginSuccess();
      } else if (result.needsVerification && result.verifyUrl != null) {
        // Open WebView for additional device verification
        Get.toNamed(AppRoutes.webview, arguments: {
          'url': result.verifyUrl!,
          'title': '登录验证',
          'type': 'login',
        });
      } else {
        AppToast.error(result.message ?? '密码登录失败');
      }
    });
  }

  // ── Common ──────────────────────────────────────────

  Future<void> _onLoginSuccess() async {
    final success = await _authRepo.confirmLogin();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshLoginStatus();
    }
    if (Get.isRegistered<PlaylistController>()) {
      Get.find<PlaylistController>().loadFolders();
    }
    Get.back();
    AppToast.success(success ? '登录成功' : '登录成功，但获取用户信息失败');
  }
}
