import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/login/captcha_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../modules/home/home_controller.dart';

class LoginController extends GetxController with GetTickerProviderStateMixin {
  late final TabController tabController;
  final _authRepo = Get.find<AuthRepository>();

  // QR Login
  final qrcodeUrl = ''.obs;
  final qrcodeKey = ''.obs;
  final qrStatus = ''.obs;
  Timer? _qrPollTimer;
  int _qrPollCount = 0;

  // SMS Login
  final phoneController = TextEditingController();
  final smsCodeController = TextEditingController();
  final countryCode = 86.obs;
  final smsCountdown = 0.obs;
  final captchaKey = ''.obs;
  Timer? _smsTimer;
  CaptchaModel? _captchaData;

  // Password Login
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;

  // Common
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    _generateQrcode();
  }

  @override
  void onClose() {
    tabController.dispose();
    _qrPollTimer?.cancel();
    _smsTimer?.cancel();
    phoneController.dispose();
    smsCodeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (tabController.index == 0) {
      _generateQrcode();
    } else {
      _qrPollTimer?.cancel();
    }
  }

  // ── QR Login ────────────────────────────────────────

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

  // ── SMS Login ───────────────────────────────────────

  Future<void> requestCaptcha() async {
    _captchaData = await _authRepo.getCaptcha();
  }

  void onCaptchaComplete(String validate, String seccode, String challenge) {
    if (_captchaData != null) {
      _captchaData!.validate = validate;
      _captchaData!.seccode = seccode;
      _captchaData!.challenge = challenge;
    }
  }

  Future<void> sendSmsCode() async {
    if (phoneController.text.isEmpty) {
      Get.snackbar('错误', '请输入手机号',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await requestCaptcha();
    if (_captchaData == null) {
      Get.snackbar('错误', '获取验证码失败',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // In production, show GeeTest WebView here and get validate/seccode
    // For now, we'll show a placeholder message
    Get.snackbar('需要验证',
        '需要极验验证，GT: ${_captchaData?.geetest?.gt}',
        snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('错误', '短信登录失败',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Called after GeeTest captcha completes for SMS flow
  Future<void> sendSmsAfterCaptcha() async {
    if (_captchaData == null) return;

    final key = await _authRepo.sendSmsCode(
      cid: countryCode.value,
      tel: int.parse(phoneController.text),
      captcha: _captchaData!,
    );

    if (key != null) {
      captchaKey.value = key;
      _startSmsCountdown();
      Get.snackbar('成功', '验证码已发送',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('错误', '验证码发送失败',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Password Login ──────────────────────────────────

  Future<void> loginByPassword() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('错误', '请填写所有字段',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await requestCaptcha();
    if (_captchaData == null) {
      Get.snackbar('错误', '获取验证码失败',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // In production, show GeeTest WebView here
    Get.snackbar('需要验证',
        '需要极验验证，GT: ${_captchaData?.geetest?.gt}',
        snackPosition: SnackPosition.BOTTOM);
  }

  // Called after GeeTest captcha completes for password flow
  Future<void> submitPasswordAfterCaptcha() async {
    if (_captchaData == null) return;
    isLoading.value = true;

    final success = await _authRepo.loginByPassword(
      username: usernameController.text,
      password: passwordController.text,
      captcha: _captchaData!,
    );

    isLoading.value = false;
    if (success) {
      _onLoginSuccess();
    } else {
      Get.snackbar('错误', '密码登录失败',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Common ──────────────────────────────────────────

  Future<void> _onLoginSuccess() async {
    // Sync cookies and fetch user info (like pilipala's confirmLogin)
    final success = await _authRepo.confirmLogin();
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().refreshLoginStatus();
    }
    Get.back();
    Get.snackbar('成功',
        success ? '登录成功' : '登录成功，但获取用户信息失败',
        snackPosition: SnackPosition.BOTTOM);
  }
}
