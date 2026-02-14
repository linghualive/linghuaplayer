class SubFolderModel {
  final int id;
  final String title;
  final String cover;
  final int mediaCount;
  final String intro;
  final int mid;
  final String name;

  SubFolderModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.mediaCount,
    required this.intro,
    required this.mid,
    required this.name,
  });

  factory SubFolderModel.fromJson(Map<String, dynamic> json) {
    final upper = json['upper'] as Map<String, dynamic>? ?? {};
    return SubFolderModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      mediaCount: json['media_count'] as int? ?? 0,
      intro: json['intro'] as String? ?? '',
      mid: upper['mid'] as int? ?? 0,
      name: upper['name'] as String? ?? '',
    );
  }
}
