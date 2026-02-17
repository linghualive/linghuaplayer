enum MusicSource { bilibili, netease }

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

  String get uniqueId =>
      source == MusicSource.netease ? 'netease_$id' : bvid;

  bool get isNetease => source == MusicSource.netease;
  bool get isBilibili => source == MusicSource.bilibili;

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
      'source': source == MusicSource.netease ? 'netease' : 'bilibili',
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
      source: json['source'] == 'netease'
          ? MusicSource.netease
          : MusicSource.bilibili,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
