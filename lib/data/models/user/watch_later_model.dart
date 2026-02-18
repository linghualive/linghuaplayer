import '../search/search_video_model.dart';

class WatchLaterModel {
  final int aid;
  final int cid;
  final String bvid;
  final String title;
  final String pic;
  final String author;
  final int mid;
  final int view;
  final int danmaku;
  final int duration;
  final int progress;

  WatchLaterModel({
    required this.aid,
    required this.cid,
    required this.bvid,
    required this.title,
    required this.pic,
    required this.author,
    this.mid = 0,
    required this.view,
    required this.danmaku,
    required this.duration,
    required this.progress,
  });

  factory WatchLaterModel.fromJson(Map<String, dynamic> json) {
    return WatchLaterModel(
      aid: json['aid'] as int? ?? 0,
      cid: json['cid'] as int? ?? 0,
      bvid: json['bvid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pic: json['pic'] as String? ?? '',
      author: json['owner']?['name'] as String? ?? '',
      mid: json['owner']?['mid'] as int? ?? 0,
      view: json['stat']?['view'] as int? ?? 0,
      danmaku: json['stat']?['danmaku'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      progress: json['progress'] as int? ?? 0,
    );
  }

  String get durationStr {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: aid,
      author: author,
      mid: mid,
      title: title,
      description: '',
      pic: pic,
      play: view,
      danmaku: danmaku,
      duration: durationStr,
      bvid: bvid,
      arcurl: '',
    );
  }
}
