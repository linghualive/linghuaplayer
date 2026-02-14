class CaptchaModel {
  final String? type;
  final String? token;
  GeetestData? geetest;
  String? validate;
  String? seccode;
  String? challenge;

  CaptchaModel({this.type, this.token, this.geetest, this.validate, this.seccode, this.challenge});

  factory CaptchaModel.fromJson(Map<String, dynamic> json) {
    return CaptchaModel(
      type: json['type'] as String?,
      token: json['token'] as String?,
      geetest: json['geetest'] != null
          ? GeetestData.fromJson(json['geetest'])
          : null,
    );
  }
}

class GeetestData {
  final String? challenge;
  final String? gt;

  GeetestData({this.challenge, this.gt});

  factory GeetestData.fromJson(Map<String, dynamic> json) {
    return GeetestData(
      challenge: json['challenge'] as String?,
      gt: json['gt'] as String?,
    );
  }
}
