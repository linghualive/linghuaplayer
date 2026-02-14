class SearchVideoModel {
  final int id;
  final String author;
  final int mid;
  final String title;
  final String description;
  final String pic;
  final int play;
  final int danmaku;
  final String duration;
  final String bvid;
  final String arcurl;

  SearchVideoModel({
    required this.id,
    required this.author,
    required this.mid,
    required this.title,
    required this.description,
    required this.pic,
    required this.play,
    required this.danmaku,
    required this.duration,
    required this.bvid,
    required this.arcurl,
  });

  factory SearchVideoModel.fromJson(Map<String, dynamic> json) {
    return SearchVideoModel(
      id: json['id'] as int? ?? 0,
      author: json['author'] as String? ?? '',
      mid: json['mid'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pic: json['pic'] as String? ?? '',
      play: _parseInt(json['play']),
      danmaku: _parseInt(json['danmaku']),
      duration: json['duration'] as String? ?? '0:00',
      bvid: json['bvid'] as String? ?? '',
      arcurl: json['arcurl'] as String? ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
