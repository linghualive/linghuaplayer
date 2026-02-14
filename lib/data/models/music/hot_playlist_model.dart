class HotPlaylistModel {
  final int menuId;
  final String title;
  final String cover;
  final int playCount;
  final String intro;

  HotPlaylistModel({
    required this.menuId,
    required this.title,
    required this.cover,
    required this.playCount,
    required this.intro,
  });

  factory HotPlaylistModel.fromJson(Map<String, dynamic> json) {
    final statistic = json['statistic'] as Map<String, dynamic>? ?? {};
    return HotPlaylistModel(
      menuId: json['menuId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      playCount: statistic['play'] as int? ?? 0,
      intro: json['intro'] as String? ?? '',
    );
  }
}
