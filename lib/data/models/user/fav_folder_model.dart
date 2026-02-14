class FavFolderModel {
  final int id;
  final String title;
  final String cover;
  final int mediaCount;
  final int attr;
  final int mid;
  final String name;
  final String face;

  FavFolderModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.mediaCount,
    required this.attr,
    required this.mid,
    required this.name,
    required this.face,
  });

  factory FavFolderModel.fromJson(Map<String, dynamic> json) {
    final upper = json['upper'] as Map<String, dynamic>? ?? {};
    return FavFolderModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      mediaCount: json['media_count'] as int? ?? 0,
      attr: json['attr'] as int? ?? 0,
      mid: upper['mid'] as int? ?? 0,
      name: upper['name'] as String? ?? '',
      face: upper['face'] as String? ?? '',
    );
  }
}
