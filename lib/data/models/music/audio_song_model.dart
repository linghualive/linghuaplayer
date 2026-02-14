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

  AudioSongModel({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.bvid,
    required this.aid,
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
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: aid,
      author: author,
      mid: 0,
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
