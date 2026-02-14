import '../../app/constants/api_constants.dart';

class IdUtils {
  /// Convert AV number to BV string
  static String av2bv(int aid) {
    final chars = ['B', 'V', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'];
    var tmp = (ApiConstants.maxAid | aid) ^ ApiConstants.xorCode;

    for (var i = chars.length - 1; i >= 3; i--) {
      chars[i] = ApiConstants.bvTable[tmp % ApiConstants.base];
      tmp ~/= ApiConstants.base;
    }

    // Swap positions 3↔9, 4↔7
    final t1 = chars[3];
    chars[3] = chars[9];
    chars[9] = t1;

    final t2 = chars[4];
    chars[4] = chars[7];
    chars[7] = t2;

    return chars.join();
  }

  /// Convert BV string to AV number
  static int bv2av(String bvid) {
    final chars = bvid.split('');

    // Swap positions 3↔9, 4↔7
    final t1 = chars[3];
    chars[3] = chars[9];
    chars[9] = t1;

    final t2 = chars[4];
    chars[4] = chars[7];
    chars[7] = t2;

    // Skip first 3 chars "BV1"
    final trimmed = chars.sublist(3);
    var tmp = 0;
    for (final c in trimmed) {
      tmp = tmp * ApiConstants.base + ApiConstants.bvTable.indexOf(c);
    }

    return ((tmp & ApiConstants.maskCode) ^ ApiConstants.xorCode).toInt();
  }

  /// Extract AV or BV from arbitrary string
  static String? matchAvorBv(String input) {
    // Try BV first
    final bvMatch = RegExp(r'[bB][vV][0-9A-Za-z]{10}').firstMatch(input);
    if (bvMatch != null) return bvMatch.group(0);

    // Try AV
    final avMatch = RegExp(r'[aA][vV]\d+').firstMatch(input);
    if (avMatch != null) return avMatch.group(0);

    return null;
  }

  /// Check if string is a BV id
  static bool isBvid(String str) {
    return RegExp(r'^[bB][vV][0-9A-Za-z]{10}$').hasMatch(str);
  }
}
