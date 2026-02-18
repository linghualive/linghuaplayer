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
  final int publisherUid;

  MvItemModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.duration,
    required this.bvid,
    required this.playCount,
    required this.publisherUid,
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
      publisherUid: json['publisher_uid'] as int? ?? json['mid'] as int? ?? 0,
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: id,
      author: artist,
      mid: publisherUid,
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
