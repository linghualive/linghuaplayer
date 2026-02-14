import '../../../shared/utils/duration_formatter.dart';
import '../search/search_video_model.dart';

class RecVideoItemModel {
  final int id;
  final String bvid;
  final int cid;
  final String goto;
  final String pic;
  final String title;
  final int duration;
  final int pubdate;
  final RecOwner owner;
  final RecStat stat;
  final String? rcmdReason;

  RecVideoItemModel({
    required this.id,
    required this.bvid,
    required this.cid,
    required this.goto,
    required this.pic,
    required this.title,
    required this.duration,
    required this.pubdate,
    required this.owner,
    required this.stat,
    this.rcmdReason,
  });

  factory RecVideoItemModel.fromJson(Map<String, dynamic> json) {
    final rcmdReasonMap = json['rcmd_reason'] as Map<String, dynamic>?;
    return RecVideoItemModel(
      id: json['id'] as int? ?? 0,
      bvid: json['bvid'] as String? ?? '',
      cid: json['cid'] as int? ?? 0,
      goto: json['goto'] as String? ?? '',
      pic: json['pic'] as String? ?? '',
      title: json['title'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      pubdate: json['pubdate'] as int? ?? 0,
      owner: RecOwner.fromJson(
          json['owner'] as Map<String, dynamic>? ?? {}),
      stat: RecStat.fromJson(
          json['stat'] as Map<String, dynamic>? ?? {}),
      rcmdReason: rcmdReasonMap?['content'] as String?,
    );
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: id,
      author: owner.name,
      mid: owner.mid,
      title: title,
      description: '',
      pic: pic,
      play: stat.view,
      danmaku: stat.danmaku,
      duration: DurationFormatter.format(duration),
      bvid: bvid,
      arcurl: 'https://www.bilibili.com/video/$bvid',
    );
  }
}

class RecOwner {
  final int mid;
  final String name;
  final String face;

  RecOwner({
    required this.mid,
    required this.name,
    required this.face,
  });

  factory RecOwner.fromJson(Map<String, dynamic> json) {
    return RecOwner(
      mid: json['mid'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      face: json['face'] as String? ?? '',
    );
  }
}

class RecStat {
  final int view;
  final int like;
  final int danmaku;

  RecStat({
    required this.view,
    required this.like,
    required this.danmaku,
  });

  factory RecStat.fromJson(Map<String, dynamic> json) {
    return RecStat(
      view: json['view'] as int? ?? 0,
      like: json['like'] as int? ?? 0,
      danmaku: json['danmaku'] as int? ?? 0,
    );
  }
}
