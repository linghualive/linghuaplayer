class QqMusicUserInfoModel {
  final String uin;
  final String nickname;
  final String avatarUrl;

  QqMusicUserInfoModel({
    required this.uin,
    required this.nickname,
    required this.avatarUrl,
  });

  factory QqMusicUserInfoModel.fromJson(Map<String, dynamic> json) {
    return QqMusicUserInfoModel(
      uin: json['uin'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uin': uin,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
    };
  }
}
