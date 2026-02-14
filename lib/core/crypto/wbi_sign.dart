import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../app/constants/api_constants.dart';
import '../http/http_client.dart';
import '../storage/storage_service.dart';
import 'package:get/get.dart';

class WbiSign {
  /// Get mixin key from imgKey + subKey using encTab shuffle
  static String getMixinKey(String orig) {
    final result = StringBuffer();
    for (final i in ApiConstants.mixinKeyEncTab) {
      if (i < orig.length) {
        result.write(orig[i]);
      }
    }
    return result.toString().substring(0, 32);
  }

  /// Sign parameters with WBI
  static Map<String, dynamic> encWbi(
    Map<String, dynamic> params,
    String mixinKey,
  ) {
    final wts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final newParams = Map<String, dynamic>.from(params);
    newParams['wts'] = wts;

    // Sort by key
    final sortedKeys = newParams.keys.toList()..sort();

    // Build query string with filtered values
    final pairs = <String>[];
    for (final key in sortedKeys) {
      final value = newParams[key].toString();
      // Filter special characters from value
      final filtered = value.replaceAll(RegExp(r"[!'()*]"), '');
      pairs.add(
          '${Uri.encodeComponent(key)}=${Uri.encodeComponent(filtered)}');
    }
    final queryStr = pairs.join('&');

    // Calculate w_rid
    final wRid = md5.convert(utf8.encode(queryStr + mixinKey)).toString();

    newParams['w_rid'] = wRid;
    return newParams;
  }

  /// Full signing flow: fetch keys if needed, then sign
  static Future<Map<String, dynamic>> makSign(
      Map<String, dynamic> params) async {
    final storage = Get.find<StorageService>();

    String? imgKey = storage.getImgKey();
    String? subKey = storage.getSubKey();
    final lastDate = storage.getWbiKeyDate();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Refresh keys if missing or stale
    if (imgKey == null || subKey == null || lastDate != today) {
      final res = await HttpClient.instance.dio
          .get(ApiConstants.navInfo);
      if (res.data['code'] == 0) {
        final wbiImg = res.data['data']['wbi_img'];
        final imgUrl = wbiImg['img_url'] as String;
        final subUrl = wbiImg['sub_url'] as String;
        imgKey = imgUrl.split('/').last.split('.').first;
        subKey = subUrl.split('/').last.split('.').first;
        storage.setWbiKeys(imgKey, subKey, today);
      }
    }

    if (imgKey == null || subKey == null) {
      return params;
    }

    final mixinKey = getMixinKey(imgKey + subKey);
    return encWbi(params, mixinKey);
  }
}
