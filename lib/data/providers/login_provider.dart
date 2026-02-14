import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/http_client.dart';

class LoginProvider {
  final _dio = HttpClient.instance.dio;

  /// Get GeeTest captcha params
  Future<Response> getCaptcha() {
    return _dio.get(
      '${ApiConstants.passBaseUrl}${ApiConstants.captcha}',
    );
  }

  /// Generate QR code for login
  Future<Response> getQrcode() {
    return _dio.get(
      '${ApiConstants.passBaseUrl}${ApiConstants.qrcodeGenerate}',
    );
  }

  /// Poll QR code login status
  Future<Response> pollQrcode(String qrcodeKey) {
    return _dio.get(
      '${ApiConstants.passBaseUrl}${ApiConstants.qrcodePoll}',
      queryParameters: {'qrcode_key': qrcodeKey},
    );
  }

  /// Send SMS verification code
  Future<Response> sendSmsCode({
    required int cid,
    required int tel,
    required String token,
    required String challenge,
    required String validate,
    required String seccode,
  }) {
    return _dio.post(
      '${ApiConstants.passBaseUrl}${ApiConstants.smsSend}',
      data: {
        'cid': cid,
        'tel': tel,
        'source': 'main_web',
        'token': token,
        'challenge': challenge,
        'validate': validate,
        'seccode': seccode,
      },
    );
  }

  /// Login with SMS code
  Future<Response> loginBySms({
    required int cid,
    required int tel,
    required int code,
    required String captchaKey,
  }) {
    return _dio.post(
      '${ApiConstants.passBaseUrl}${ApiConstants.smsLogin}',
      data: {
        'cid': cid,
        'tel': tel,
        'code': code,
        'source': 'main_mini',
        'keep': 0,
        'captcha_key': captchaKey,
        'go_url': 'https://www.bilibili.com',
      },
    );
  }

  /// Get RSA public key for password encryption
  Future<Response> getWebKey() {
    return _dio.get(
      '${ApiConstants.passBaseUrl}${ApiConstants.webKey}',
      queryParameters: {'disable_rcmd': 0},
    );
  }

  /// Login with username and password
  Future<Response> loginByPassword({
    required String username,
    required String password,
    required String token,
    required String challenge,
    required String validate,
    required String seccode,
  }) {
    return _dio.post(
      '${ApiConstants.passBaseUrl}${ApiConstants.webLogin}',
      data: {
        'username': username,
        'password': password,
        'keep': 0,
        'token': token,
        'challenge': challenge,
        'validate': validate,
        'seccode': seccode,
        'source': 'main-fe-header',
        'go_url': 'https://www.bilibili.com',
      },
    );
  }

  /// Get current user info (also returns WBI keys)
  Future<Response> getUserInfo() {
    return _dio.get(ApiConstants.navInfo);
  }
}
