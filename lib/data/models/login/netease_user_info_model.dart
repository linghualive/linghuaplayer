class NeteaseUserInfoModel {
  final int userId;
  final String nickname;
  final String avatarUrl;
  final int vipType;

  NeteaseUserInfoModel({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.vipType,
  });

  factory NeteaseUserInfoModel.fromJson(Map<String, dynamic> json) {
    return NeteaseUserInfoModel(
      userId: json['userId'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      vipType: json['vipType'] as int? ?? 0,
    );
  }

  /// Parse from the `/api/w/nuser/account/get` response profile field.
  factory NeteaseUserInfoModel.fromAccountResponse(
      Map<String, dynamic> response) {
    final profile = response['profile'] as Map<String, dynamic>? ?? {};
    return NeteaseUserInfoModel.fromJson(profile);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'vipType': vipType,
    };
  }

  bool get isVip => vipType > 0;
}
