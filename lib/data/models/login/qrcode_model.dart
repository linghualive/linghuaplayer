class QrcodeModel {
  final String? url;
  final String? qrcodeKey;

  QrcodeModel({this.url, this.qrcodeKey});

  factory QrcodeModel.fromJson(Map<String, dynamic> json) {
    return QrcodeModel(
      url: json['url'] as String?,
      qrcodeKey: json['qrcode_key'] as String?,
    );
  }
}

class QrcodePollResult {
  final int code;
  final String? url;
  final String? refreshToken;
  final int? timestamp;
  final String? message;

  QrcodePollResult({
    required this.code,
    this.url,
    this.refreshToken,
    this.timestamp,
    this.message,
  });

  factory QrcodePollResult.fromJson(Map<String, dynamic> json) {
    return QrcodePollResult(
      code: json['code'] as int? ?? -1,
      url: json['url'] as String?,
      refreshToken: json['refresh_token'] as String?,
      timestamp: json['timestamp'] as int?,
      message: json['message'] as String?,
    );
  }

  bool get isSuccess => code == 0;
  bool get isExpired => code == 86038;
  bool get isScanned => code == 86090;
  bool get isWaiting => code == 86101;
}
