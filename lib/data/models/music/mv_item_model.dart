import '../../../shared/utils/duration_formatter.dart';
import '../search/search_video_model.dart';

class MvItemModel {
  final int id;
  final String title;
  final String artist;
  final String cover;
  final int duration;
  final String bvid;
  final int playCount;

  MvItemModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.duration,
    required this.bvid,
    required this.playCount,
  });

  factory MvItemModel.fromJson(Map<String, dynamic> json) {
    return MvItemModel(
      id: json['aid'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      artist: json['publisher_name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      bvid: json['bvid'] as String? ?? '',
      playCount: json['click'] as int? ?? 0,
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: id,
      author: artist,
      mid: 0,
      title: title,
      description: '',
      pic: cover,
      play: playCount,
      danmaku: 0,
      duration: DurationFormatter.format(duration),
      bvid: bvid,
      arcurl: 'https://www.bilibili.com/video/$bvid',
    );
  }
}
