import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:get/get.dart';
import 'package:pointycastle/asymmetric/api.dart';

import '../../core/crypto/aurora_eid.dart';
import '../../core/http/http_client.dart';
import '../../core/storage/storage_service.dart';
import '../models/login/captcha_model.dart';
import '../models/login/qrcode_model.dart';
import '../models/login/user_info_model.dart';
import '../providers/login_provider.dart';

class AuthRepository {
  final _provider = Get.find<LoginProvider>();
  final _storage = Get.find<StorageService>();

  /// Get GeeTest captcha parameters
  Future<CaptchaModel?> getCaptcha() async {
    final res = await _provider.getCaptcha();
    if (res.data['code'] == 0) {
      return CaptchaModel.fromJson(res.data['data']);
    }
    return null;
  }

  /// Generate QR code for scanning
  Future<QrcodeModel?> getQrcode() async {
    final res = await _provider.getQrcode();
    if (res.data['code'] == 0) {
      return QrcodeModel.fromJson(res.data['data']);
    }
    return null;
  }

  /// Poll QR code status
  Future<QrcodePollResult> pollQrcode(String qrcodeKey) async {
    final res = await _provider.pollQrcode(qrcodeKey);
    if (res.data['code'] == 0) {
      return QrcodePollResult.fromJson(res.data['data']);
    }
    return QrcodePollResult(code: -1, message: res.data['message']);
  }

  /// Send SMS verification code
  Future<String?> sendSmsCode({
    required int cid,
    required int tel,
    required CaptchaModel captcha,
  }) async {
    final res = await _provider.sendSmsCode(
      cid: cid,
      tel: tel,
      token: captcha.token ?? '',
      challenge: captcha.challenge ?? captcha.geetest?.challenge ?? '',
      validate: captcha.validate ?? '',
      seccode: captcha.seccode ?? '',
    );
    if (res.data['code'] == 0) {
      return res.data['data']['captcha_key'] as String?;
    }
    return null;
  }

  /// Login with SMS code
  Future<bool> loginBySms({
    required int cid,
    required int tel,
    required int code,
    required String captchaKey,
  }) async {
    final res = await _provider.loginBySms(
      cid: cid,
      tel: tel,
      code: code,
      captchaKey: captchaKey,
    );
    if (res.data['code'] == 0) {
      await confirmLogin();
      return true;
    }
    return false;
  }

  /// Login with password (RSA encrypted).
  /// Returns [PasswordLoginResult] with status, message, and optional
  /// verification URL when additional device verification is required.
  Future<PasswordLoginResult> loginByPassword({
    required String username,
    required String password,
    required CaptchaModel captcha,
  }) async {
    // 1. Get RSA public key
    final keyRes = await _provider.getWebKey();
    if (keyRes.data['code'] != 0) {
      return PasswordLoginResult(
        success: false,
        message: keyRes.data['message'] ?? '获取密钥失败',
      );
    }

    final rhash = keyRes.data['data']['hash'] as String;
    final publicKeyPem = keyRes.data['data']['key'] as String;

    // 2. Parse PEM and encrypt password
    final publicKey = encrypt_pkg.RSAKeyParser().parse(publicKeyPem)
        as RSAPublicKey;
    final encrypter =
        encrypt_pkg.Encrypter(encrypt_pkg.RSA(publicKey: publicKey));
    final encryptedPassword = encrypter.encrypt(rhash + password).base64;

    // 3. Login
    final res = await _provider.loginByPassword(
      username: username,
      password: encryptedPassword,
      token: captcha.token ?? '',
      challenge: captcha.challenge ?? captcha.geetest?.challenge ?? '',
      validate: captcha.validate ?? '',
      seccode: captcha.seccode ?? '',
    );

    if (res.data['code'] == 0 && res.data['data']?['status'] == 0) {
      await confirmLogin();
      return PasswordLoginResult(success: true);
    }

    // status != 0 means additional verification is needed
    if (res.data['code'] == 0 && res.data['data']?['status'] != 0) {
      final verifyUrl = res.data['data']?['url'] as String?;
      return PasswordLoginResult(
        success: false,
        needsVerification: true,
        verifyUrl: verifyUrl,
        message: '需要安全验证',
      );
    }

    return PasswordLoginResult(
      success: false,
      message: res.data['message'] ?? '登录失败',
    );
  }

  /// Post-login: fetch user info, set headers, cache
  Future<bool> confirmLogin() async {
    final res = await _provider.getUserInfo();
    if (res.data['code'] != 0) return false;

    final data = res.data['data'] as Map<String, dynamic>;
    if (data['isLogin'] != true) return false;

    final userInfo = UserInfoModel.fromJson(data);

    // Cache user info
    _storage.setUserInfo(userInfo.toJson());
    _storage.isLoggedIn = true;
    _storage.userMid = userInfo.mid.toString();

    // Set auth headers
    final auroraEid = AuroraEid.generate(userInfo.mid);
    HttpClient.instance.setAuthHeaders(
      mid: userInfo.mid.toString(),
      auroraEid: auroraEid,
    );

    return true;
  }

  /// Get cached user info
  UserInfoModel? getCachedUserInfo() {
    final data = _storage.getUserInfo();
    if (data != null) {
      return UserInfoModel.fromJson(data);
    }
    return null;
  }

  /// Logout: clear cookies, headers, storage
  Future<void> logout() async {
    _storage.clearAuth();
    HttpClient.instance.clearAuthHeaders();
    await HttpClient.instance.cookieJar.deleteAll();
  }

  /// Check if user is logged in
  bool get isLoggedIn => _storage.isLoggedIn;
}

class PasswordLoginResult {
  final bool success;
  final bool needsVerification;
  final String? verifyUrl;
  final String? message;

  PasswordLoginResult({
    required this.success,
    this.needsVerification = false,
    this.verifyUrl,
    this.message,
  });
}
