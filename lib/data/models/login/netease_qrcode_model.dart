class NeteaseQrcodePollResult {
  final int code;
  final String? message;

  NeteaseQrcodePollResult({
    required this.code,
    this.message,
  });

  factory NeteaseQrcodePollResult.fromJson(Map<String, dynamic> json) {
    return NeteaseQrcodePollResult(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String?,
    );
  }

  /// 800: QR code expired
  bool get isExpired => code == 800;

  /// 801: Waiting for scan
  bool get isWaiting => code == 801;

  /// 802: Scanned, waiting for confirmation
  bool get isScanned => code == 802;

  /// 803: Login success
  bool get isSuccess => code == 803;
}
