/// Deprecated: Use string-based sourceId via MusicSourceRegistry instead.
/// This enum is kept for backward compatibility during the migration period.
@Deprecated('Use string-based sourceId via MusicSourceAdapter/MusicSourceRegistry')
enum MusicSource { bilibili, netease, qqmusic }

/// Legacy unified search result model.
///
/// New code should use [Track] from `lib/data/models/track.dart` instead.
/// This class is kept for backward compatibility and will be replaced
/// incrementally. Use [Track.fromSearchVideoModel] and
/// [track.toSearchVideoModel()] for bridging.
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
  final MusicSource source;

  SearchVideoModel({
    required this.id,
    required this.author,
    this.mid = 0,
    required this.title,
    this.description = '',
    this.pic = '',
    this.play = 0,
    this.danmaku = 0,
    required this.duration,
    this.bvid = '',
    this.arcurl = '',
    this.source = MusicSource.bilibili,
  });

  String get uniqueId {
    switch (source) {
      case MusicSource.netease:
        return 'netease_$id';
      case MusicSource.qqmusic:
        return 'qqmusic_$id';
      case MusicSource.bilibili:
        return bvid;
    }
  }

  bool get isNetease => source == MusicSource.netease;
  bool get isBilibili => source == MusicSource.bilibili;
  bool get isQQMusic => source == MusicSource.qqmusic;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'mid': mid,
      'title': title,
      'description': description,
      'pic': pic,
      'play': play,
      'danmaku': danmaku,
      'duration': duration,
      'bvid': bvid,
      'arcurl': arcurl,
      'source': source.name,
    };
  }

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
      source: _parseSource(json['source']),
    );
  }

  static MusicSource _parseSource(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'netease':
          return MusicSource.netease;
        case 'qqmusic':
          return MusicSource.qqmusic;
        default:
          return MusicSource.bilibili;
      }
    }
    return MusicSource.bilibili;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
