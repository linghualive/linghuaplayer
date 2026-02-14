/// Video quality IDs from Bilibili's DASH API
class VideoQualityId {
  static const int k240 = 6;
  static const int k360 = 16;
  static const int k480 = 32;
  static const int k720 = 64;
  static const int k1080 = 80;
  static const int k4K = 120;
  static const int k8K = 127;

  static String label(int id) {
    switch (id) {
      case k8K:
        return '8K';
      case k4K:
        return '4K';
      case k1080:
        return '1080P';
      case k720:
        return '720P';
      case k480:
        return '480P';
      case k360:
        return '360P';
      case k240:
        return '240P';
      default:
        return '${id}P';
    }
  }
}

/// Video codec IDs from Bilibili's DASH API
class VideoCodecId {
  static const int avc = 7; // H.264
  static const int hevc = 12; // H.265
  static const int av1 = 13; // AV1
}

class VideoStreamModel {
  final int id; // quality code
  final String baseUrl;
  final String? backupUrl;
  final int bandwidth;
  final String mimeType;
  final String codecs;
  final int codecid;
  final int width;
  final int height;
  final String frameRate;

  VideoStreamModel({
    required this.id,
    required this.baseUrl,
    this.backupUrl,
    required this.bandwidth,
    required this.mimeType,
    required this.codecs,
    required this.codecid,
    required this.width,
    required this.height,
    required this.frameRate,
  });

  String get qualityLabel => VideoQualityId.label(id);

  bool get isAvc => codecid == VideoCodecId.avc;

  factory VideoStreamModel.fromJson(Map<String, dynamic> json) {
    String? backup;
    if (json['backupUrl'] != null && json['backupUrl'] is List) {
      final list = json['backupUrl'] as List;
      if (list.isNotEmpty) backup = list.first.toString();
    } else if (json['backup_url'] != null && json['backup_url'] is List) {
      final list = json['backup_url'] as List;
      if (list.isNotEmpty) backup = list.first.toString();
    }

    return VideoStreamModel(
      id: json['id'] as int? ?? 0,
      baseUrl:
          json['baseUrl'] as String? ?? json['base_url'] as String? ?? '',
      backupUrl: backup,
      bandwidth: json['bandWidth'] as int? ?? json['bandwidth'] as int? ?? 0,
      mimeType:
          json['mime_type'] as String? ?? json['mimeType'] as String? ?? '',
      codecs: json['codecs'] as String? ?? '',
      codecid: json['codecid'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      frameRate: json['frameRate'] as String? ?? json['frame_rate'] as String? ?? '',
    );
  }
}
