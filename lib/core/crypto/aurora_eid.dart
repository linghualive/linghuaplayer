import 'dart:convert';

import '../../app/constants/app_constants.dart';

class AuroraEid {
  static String? generate(int uid) {
    if (uid == 0) return null;
    final uidString = uid.toString();
    final key = AppConstants.auroraEidKey;
    final resultBytes = List<int>.generate(
      uidString.length,
      (i) => uidString.codeUnitAt(i) ^ key.codeUnitAt(i % key.length),
    );
    var encoded = base64Url.encode(resultBytes);
    // Remove trailing '=' padding
    encoded = encoded.replaceAll(RegExp(r'=*$'), '');
    return encoded;
  }
}
