import '../search/search_video_model.dart';

class SubResourceModel {
  final int id;
  final String title;
  final String cover;
  final String bvid;
  final int duration;
  final int pubtime;

  SubResourceModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.bvid,
    required this.duration,
    required this.pubtime,
  });

  factory SubResourceModel.fromJson(Map<String, dynamic> json) {
    return SubResourceModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      bvid: json['bvid'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      pubtime: json['pubtime'] as int? ?? 0,
    );
  }

  String get durationStr {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: id,
      author: '',
      mid: 0,
      title: title,
      description: '',
      pic: cover,
      play: 0,
      danmaku: 0,
      duration: durationStr,
      bvid: bvid,
      arcurl: '',
    );
  }
}
