import '../search/search_video_model.dart';

class HistoryModel {
  final String title;
  final String cover;
  final String bvid;
  final int cid;
  final String business;
  final int progress;
  final int viewAt;
  final int duration;
  final String authorName;
  final int kid;

  HistoryModel({
    required this.title,
    required this.cover,
    required this.bvid,
    required this.cid,
    required this.business,
    required this.progress,
    required this.viewAt,
    required this.duration,
    required this.authorName,
    required this.kid,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    final history = json['history'] as Map<String, dynamic>? ?? {};
    return HistoryModel(
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      bvid: history['bvid'] as String? ?? '',
      cid: history['cid'] as int? ?? 0,
      business: history['business'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      viewAt: json['view_at'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? '',
      kid: json['kid'] as int? ?? 0,
    );
  }

  String get durationStr {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get progressStr {
    if (progress <= 0) return '';
    final minutes = progress ~/ 60;
    final seconds = progress % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get relativeTime {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - viewAt;
    if (diff < 60) return 'Just now';
    if (diff < 3600) return '${diff ~/ 60} min ago';
    if (diff < 86400) return '${diff ~/ 3600} hr ago';
    if (diff < 2592000) return '${diff ~/ 86400} days ago';
    return '${diff ~/ 2592000} months ago';
  }

  SearchVideoModel toSearchVideoModel() {
    return SearchVideoModel(
      id: kid,
      author: authorName,
      mid: 0,
      title: title,
      description: '',
      pic: cover,
      play: 0,
      danmaku: 0,
      duration: durationStr,
      bvid: bvid,
      arcurl: '',
    );
  }
}
