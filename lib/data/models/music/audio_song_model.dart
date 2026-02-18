import '../../../shared/utils/duration_formatter.dart';
import '../search/search_video_model.dart';

class AudioSongModel {
  final int id;
  final String title;
  final String author;
  final String cover;
  final int duration;
  final String bvid;
  final int aid;
  final int uid;

  AudioSongModel({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.bvid,
    required this.aid,
    this.uid = 0,
  });

  factory AudioSongModel.fromJson(Map<String, dynamic> json) {
    return AudioSongModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      bvid: json['bvid'] as String? ?? '',
      aid: json['aid'] as int? ?? 0,
      uid: json['uid'] as int? ?? json['mid'] as int? ?? 0,
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: aid,
      author: author,
      mid: uid,
      title: title,
      description: '',
      pic: cover,
      play: 0,
      danmaku: 0,
      duration: DurationFormatter.format(duration),
      bvid: bvid,
      arcurl: 'https://www.bilibili.com/video/$bvid',
    );
  }
}
