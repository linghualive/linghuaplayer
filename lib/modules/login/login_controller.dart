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
    qrStatus.value = 'Loading QR code...';
    final qrcode = await _authRepo.getQrcode();
    if (qrcode != null) {
      qrcodeUrl.value = qrcode.url ?? '';
      qrcodeKey.value = qrcode.qrcodeKey ?? '';
      qrStatus.value = 'Scan with Bilibili app';
      _startQrPolling();
    } else {
      qrStatus.value = 'Failed to generate QR code';
    }
  }

  void _startQrPolling() {
    _qrPollCount = 0;
    _qrPollTimer?.cancel();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _qrPollCount++;
      if (_qrPollCount > 180) {
        timer.cancel();
        qrStatus.value = 'QR code expired';
        return;
      }
      if (qrcodeKey.value.isEmpty) return;

      final result = await _authRepo.pollQrcode(qrcodeKey.value);
      if (result.isSuccess) {
        timer.cancel();
        qrStatus.value = 'Login successful!';
        await _onLoginSuccess();
      } else if (result.isScanned) {
        qrStatus.value = 'Scanned, confirm on phone';
      } else if (result.isExpired) {
        timer.cancel();
        qrStatus.value = 'QR code expired';
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
      Get.snackbar('Error', 'Please enter phone number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await requestCaptcha();
    if (_captchaData == null) {
      Get.snackbar('Error', 'Failed to get captcha',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // In production, show GeeTest WebView here and get validate/seccode
    // For now, we'll show a placeholder message
    Get.snackbar('Captcha Required',
        'GeeTest verification needed. GT: ${_captchaData?.geetest?.gt}',
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
      Get.snackbar('Error', 'SMS login failed',
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
      Get.snackbar('Success', 'SMS code sent',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', 'Failed to send SMS',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Password Login ──────────────────────────────────

  Future<void> loginByPassword() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await requestCaptcha();
    if (_captchaData == null) {
      Get.snackbar('Error', 'Failed to get captcha',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // In production, show GeeTest WebView here
    Get.snackbar('Captcha Required',
        'GeeTest verification needed. GT: ${_captchaData?.geetest?.gt}',
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
      Get.snackbar('Error', 'Password login failed',
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
    Get.snackbar('Success',
        success ? 'Login successful' : 'Login OK but failed to fetch user info',
        snackPosition: SnackPosition.BOTTOM);
  }
}
