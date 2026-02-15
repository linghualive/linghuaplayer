import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto_pkg;
import 'package:encrypt/encrypt.dart';

/// NetEase Cloud Music WEAPI encryption.
///
/// Implements the 2-layer AES-CBC + RSA encryption used by the web client.
class NeteaseCrypto {
  static const _presetKey = '0CoJUm6Qyw8W8jud';
  static const _iv = '0102030405060708';
  static const _base62 =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  // RSA public key modulus (hex) – extracted from the PEM key used by NeteaseCloudMusicApi
  static const _rsaPublicKeyModulus =
      '00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7'
      'b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280'
      '104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932'
      '575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b'
      '3ece0462db0a22b8e7';
  static const _rsaPublicKeyExponent = '010001';

  static final _random = Random.secure();

  /// Generate a random 16-character base62 string.
  static String _generateSecretKey() {
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      sb.write(_base62[_random.nextInt(62)]);
    }
    return sb.toString();
  }

  /// AES-CBC encrypt, return base64.
  static String _aesCbcEncrypt(String plaintext, String keyStr, String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.encrypt(plaintext, iv: iv).base64;
  }

  /// RSA encrypt with no padding (raw modular exponentiation).
  /// Input is the reversed secretKey, output is hex string.
  static String _rsaEncrypt(String text) {
    // Reverse the text
    final reversed = text.split('').reversed.join();

    // Convert text to BigInt (treat each char as a byte)
    final bytes = utf8.encode(reversed);
    final inputBigInt = _bytesToBigInt(Uint8List.fromList(bytes));

    // Parse modulus and exponent
    final modulus = BigInt.parse(_rsaPublicKeyModulus, radix: 16);
    final exponent = BigInt.parse(_rsaPublicKeyExponent, radix: 16);

    // Raw RSA: result = input^exponent mod modulus
    final result = inputBigInt.modPow(exponent, modulus);

    // Convert to hex, left-pad to 256 hex chars (128 bytes = 1024-bit key output)
    return result.toRadixString(16).padLeft(256, '0');
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  /// Encrypt data using WEAPI method.
  /// Returns a map with `params` and `encSecKey`.
  static Map<String, String> weapi(Map<String, dynamic> data) {
    final text = jsonEncode(data);
    final secretKey = _generateSecretKey();

    // Layer 1: encrypt with preset key
    final encrypted1 = _aesCbcEncrypt(text, _presetKey, _iv);
    // Layer 2: encrypt with random secret key
    final params = _aesCbcEncrypt(encrypted1, secretKey, _iv);
    // RSA encrypt the reversed secret key
    final encSecKey = _rsaEncrypt(secretKey);

    return {
      'params': params,
      'encSecKey': encSecKey,
    };
  }

  /// AES-ECB encrypt for EAPI, return uppercase hex.
  static String _aesEcbEncryptHex(String plaintext, String keyStr) {
    final key = Key.fromUtf8(keyStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plaintext);
    return encrypted.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  /// Encrypt data using EAPI method.
  /// Returns a map with `params`.
  static Map<String, String> eapi(String url, Map<String, dynamic> data) {
    const eapiKey = 'e82ckenh8dichen8';
    final text = jsonEncode(data);
    final message = 'nobody${url}use${text}md5forencrypt';
    final digest = crypto_pkg.md5.convert(utf8.encode(message)).toString();
    final payload = '$url-36cd479b6b5-$text-36cd479b6b5-$digest';
    return {
      'params': _aesEcbEncryptHex(payload, eapiKey),
    };
  }

  /// Generate a random Chinese IP address for X-Real-IP header.
  static String generateRandomCNIP() {
    // Common Chinese IP ranges
    const ranges = [
      [0x6F000000, 0x6FFFFFFF], // 111.x.x.x
      [0x70000000, 0x70FFFFFF], // 112.x.x.x
      [0x72000000, 0x72FFFFFF], // 114.x.x.x
      [0x74000000, 0x74FFFFFF], // 116.x.x.x
      [0x77000000, 0x77FFFFFF], // 119.x.x.x
      [0x7A000000, 0x7AFFFFFF], // 122.x.x.x
      [0xB6000000, 0xB6FFFFFF], // 182.x.x.x
      [0xB7000000, 0xB7FFFFFF], // 183.x.x.x
    ];
    final range = ranges[_random.nextInt(ranges.length)];
    final ip = range[0] + _random.nextInt(range[1] - range[0]);
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }
}
