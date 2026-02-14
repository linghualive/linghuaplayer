class VideoDetailModel {
  final int cid;
  final int page;
  final String part;
  final int duration;
  final String? firstFrame;

  VideoDetailModel({
    required this.cid,
    required this.page,
    required this.part,
    required this.duration,
    this.firstFrame,
  });

  factory VideoDetailModel.fromJson(Map<String, dynamic> json) {
    return VideoDetailModel(
      cid: json['cid'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      part: json['part'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      firstFrame: json['first_frame'] as String?,
    );
  }
}
