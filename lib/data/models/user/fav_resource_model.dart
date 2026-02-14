import '../search/search_video_model.dart';

class FavResourceModel {
  final int id;
  final String title;
  final String pic;
  final String bvid;
  final int cid;
  final String author;
  final int play;
  final int danmaku;
  final int duration;
  final int favTime;

  FavResourceModel({
    required this.id,
    required this.title,
    required this.pic,
    required this.bvid,
    required this.cid,
    required this.author,
    required this.play,
    required this.danmaku,
    required this.duration,
    required this.favTime,
  });

  factory FavResourceModel.fromJson(Map<String, dynamic> json) {
    final upper = json['upper'] as Map<String, dynamic>? ?? {};
    final cntInfo = json['cnt_info'] as Map<String, dynamic>? ?? {};
    return FavResourceModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      pic: json['cover'] as String? ?? '',
      bvid: json['bvid'] as String? ?? '',
      cid: json['ugc']?['first_cid'] as int? ?? 0,
      author: upper['name'] as String? ?? '',
      play: cntInfo['play'] as int? ?? 0,
      danmaku: cntInfo['danmaku'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      favTime: json['fav_time'] as int? ?? 0,
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
      author: author,
      mid: 0,
      title: title,
      description: '',
      pic: pic,
      play: play,
      danmaku: danmaku,
      duration: durationStr,
      bvid: bvid,
      arcurl: '',
    );
  }
}
