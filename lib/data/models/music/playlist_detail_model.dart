class PlaylistDetailModel {
  final int menuId;
  final String title;
  final String cover;
  final String intro;
  final int playCount;
  final int songCount;
  final String author;

  PlaylistDetailModel({
    required this.menuId,
    required this.title,
    required this.cover,
    required this.intro,
    required this.playCount,
    required this.songCount,
    required this.author,
  });

  factory PlaylistDetailModel.fromJson(Map<String, dynamic> json) {
    return PlaylistDetailModel(
      menuId: json['menuId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      playCount: json['playCount'] as int? ?? 0,
      songCount: json['songCount'] as int? ?? 0,
      author: json['uname'] as String? ?? '',
    );
  }
}
