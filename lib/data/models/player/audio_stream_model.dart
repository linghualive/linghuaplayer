/// Audio quality tier IDs from Bilibili's DASH API
class AudioQualityId {
  static const int k64 = 30216;
  static const int k132 = 30232;
  static const int k192 = 30280;
  static const int dolby = 30250;
  static const int hiRes = 30251;

  /// Priority order: higher = better quality
  static int priority(int id) {
    switch (id) {
      case hiRes:
        return 5;
      case dolby:
        return 4;
      case k192:
        return 3;
      case k132:
        return 2;
      case k64:
        return 1;
      default:
        return 0;
    }
  }

  static String label(int id) {
    switch (id) {
      case hiRes:
        return 'Hi-Res';
      case dolby:
        return 'Dolby';
      case k192:
        return '192K';
      case k132:
        return '132K';
      case k64:
        return '64K';
      default:
        return '$id';
    }
  }
}

class AudioStreamModel {
  final int id;
  final String baseUrl;
  final String? backupUrl;
  final int bandwidth;
  final String mimeType;
  final String codecs;
  final int codecid;

  AudioStreamModel({
    required this.id,
    required this.baseUrl,
    this.backupUrl,
    required this.bandwidth,
    required this.mimeType,
    required this.codecs,
    required this.codecid,
  });

  /// Human-readable quality label
  String get qualityLabel => AudioQualityId.label(id);

  /// Quality priority for sorting (higher = better)
  int get qualityPriority => AudioQualityId.priority(id);

  /// Whether this is a premium (Dolby/Hi-Res) stream
  bool get isPremium =>
      id == AudioQualityId.dolby || id == AudioQualityId.hiRes;

  factory AudioStreamModel.fromJson(Map<String, dynamic> json) {
    // Bilibili API returns camelCase field names: baseUrl, backupUrl, bandWidth
    String? backup;
    if (json['backupUrl'] != null && json['backupUrl'] is List) {
      final list = json['backupUrl'] as List;
      if (list.isNotEmpty) backup = list.first.toString();
    } else if (json['backup_url'] != null && json['backup_url'] is List) {
      final list = json['backup_url'] as List;
      if (list.isNotEmpty) backup = list.first.toString();
    }

    return AudioStreamModel(
      id: json['id'] as int? ?? 0,
      baseUrl:
          json['baseUrl'] as String? ?? json['base_url'] as String? ?? '',
      backupUrl: backup,
      bandwidth: json['bandWidth'] as int? ?? json['bandwidth'] as int? ?? 0,
      mimeType:
          json['mime_type'] as String? ?? json['mimeType'] as String? ?? '',
      codecs: json['codecs'] as String? ?? '',
      codecid: json['codecid'] as int? ?? 0,
    );
  }
}
