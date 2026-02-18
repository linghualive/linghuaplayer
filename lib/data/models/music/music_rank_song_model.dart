import '../../../shared/utils/duration_formatter.dart';
import '../search/search_video_model.dart';

class MusicRankSongModel {
  final int rank;
  final String title;
  final String artist;
  final String cover;
  final String bvid;
  final int duration;
  final int playCount;
  final int aid;
  final int uid;

  MusicRankSongModel({
    required this.rank,
    required this.title,
    required this.artist,
    required this.cover,
    required this.bvid,
    required this.duration,
    required this.playCount,
    required this.aid,
    this.uid = 0,
  });

  factory MusicRankSongModel.fromJson(Map<String, dynamic> json) {
    return MusicRankSongModel(
      rank: json['rank'] as int? ?? 0,
      title: json['music_title'] as String? ?? '',
      artist: json['singer'] as String? ?? '',
      cover: json['mv_cover'] as String? ?? json['creation_cover'] as String? ?? '',
      bvid: (json['creation_bvid'] as String?)?.isNotEmpty == true
          ? json['creation_bvid'] as String
          : json['mv_bvid'] as String? ?? '',
      duration: json['creation_duration'] as int? ?? 0,
      playCount: json['creation_play'] as int? ?? json['heat'] as int? ?? 0,
      aid: json['creation_aid'] as int? ?? json['mv_aid'] as int? ?? 0,
      uid: json['creation_uid'] as int? ?? json['uid'] as int? ?? json['mid'] as int? ?? 0,
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: aid,
      author: artist,
      mid: uid,
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
