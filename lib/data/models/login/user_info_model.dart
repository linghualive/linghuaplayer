class UserInfoModel {
  final bool isLogin;
  final int mid;
  final String uname;
  final String face;
  final int currentLevel;
  final bool isVip;

  UserInfoModel({
    required this.isLogin,
    required this.mid,
    required this.uname,
    required this.face,
    required this.currentLevel,
    required this.isVip,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      isLogin: json['isLogin'] as bool? ?? false,
      mid: json['mid'] as int? ?? 0,
      uname: json['uname'] as String? ?? '',
      face: json['face'] as String? ?? '',
      currentLevel: json['level_info']?['current_level'] as int? ?? 0,
      isVip: (json['vipStatus'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLogin': isLogin,
      'mid': mid,
      'uname': uname,
      'face': face,
      'level_info': {'current_level': currentLevel},
      'vipStatus': isVip ? 1 : 0,
    };
  }
}
