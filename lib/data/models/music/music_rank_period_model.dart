class MusicRankPeriodModel {
  final int id;
  final int priod;
  final int publishTime;

  MusicRankPeriodModel({
    required this.id,
    required this.priod,
    required this.publishTime,
  });

  String get name => '第$priod期';

  factory MusicRankPeriodModel.fromJson(Map<String, dynamic> json) {
    return MusicRankPeriodModel(
      id: json['ID'] as int? ?? 0,
      priod: json['priod'] as int? ?? 0,
      publishTime: json['publish_time'] as int? ?? 0,
    );
  }
}
