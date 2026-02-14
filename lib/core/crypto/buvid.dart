import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/api_constants.dart';
import '../http/http_client.dart';

class BuvidUtil {
  static final _random = Random();

  /// Generate a BUVID locally from random MAC address
  static String generateBuvid() {
    // Generate 6 random hex segments (MAC address style)
    final segments = List.generate(6, (_) {
      return _random.nextInt(256).toRadixString(16).padLeft(2, '0');
    });
    final mac = segments.join(':');
    final md5Str = md5.convert(utf8.encode(mac)).toString();
    return 'XY${md5Str[2]}${md5Str[12]}${md5Str[22]}$md5Str';
  }

  /// Alternative BUVID generation using UUID
  static String generateBuvidFromUuid() {
    const uuid = Uuid();
    final part1 = uuid.v4().replaceAll('-', '');
    final part2 = uuid.v4().replaceAll('-', '');
    final combined = (part1 + part2).substring(0, 35).toUpperCase();
    return 'XY$combined';
  }

  /// Fetch buvid3 from server, or generate locally
  static Future<String> getBuvid() async {
    try {
      // Check cookie first
      final cookies = await HttpClient.instance.cookieJar
          .loadForRequest(Uri.parse(ApiConstants.apiBaseUrl));
      final buvid3Cookies =
          cookies.where((c) => c.name == 'buvid3');
      if (buvid3Cookies.isNotEmpty) {
        return buvid3Cookies.first.value;
      }

      // Fetch from server
      final res = await HttpClient.instance.dio
          .get(ApiConstants.fingerSpi);
      if (res.data['code'] == 0) {
        return res.data['data']['b_3'] as String;
      }
    } catch (_) {}

    return generateBuvid();
  }

  /// Activate BUVID by simulating browser fingerprint
  static Future<void> activate() async {
    try {
      // Step 1: Get spm_prefix from space page
      final spaceRes = await HttpClient.instance.dio.get(
        'https://space.bilibili.com/1/dynamic',
        options: Options(responseType: ResponseType.plain),
      );
      final html = spaceRes.data.toString();
      final spmMatch =
          RegExp(r'<meta name="spm_prefix" content="([^"]+)">')
              .firstMatch(html);
      final spmPrefix = spmMatch?.group(1) ?? '333.999';

      // Step 2: Generate random payload
      final randBytes =
          List.generate(50, (_) => _random.nextInt(256));
      final randStr = base64Encode(randBytes).substring(0, 50);

      // Step 3: POST activation
      final payload = json.encode({
        '3064': 1,
        '39c8': '$spmPrefix.fp.risk',
        '3c43': {
          'adca': 'Linux',
          'bfe9': randStr,
        },
      });

      await HttpClient.instance.dio.post(
        ApiConstants.buvidActivate,
        data: json.encode({'payload': payload}),
        options: Options(contentType: 'application/json'),
      );
    } catch (_) {
      // Activation failure is non-fatal
    }
  }
}
