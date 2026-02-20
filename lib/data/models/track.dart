import 'search/search_video_model.dart';

/// Unified track model that replaces source-specific models.
///
/// Each track carries a [sourceId] and [sourceTrackId] to identify
/// its origin, plus an [extra] map for source-specific fields.
class Track {
  final String sourceTrackId;
  final String sourceId;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final String durationText;
  final String uniqueId;
  final Map<String, dynamic> extra;

  Track({
    required this.sourceTrackId,
    required this.sourceId,
    required this.title,
    required this.artist,
    this.album = '',
    this.coverUrl = '',
    required this.durationText,
    String? uniqueId,
    this.extra = const {},
  }) : uniqueId = uniqueId ?? '$sourceId:$sourceTrackId';

  /// Bridge: create a Track from the legacy SearchVideoModel.
  factory Track.fromSearchVideoModel(SearchVideoModel video) {
    if (video.isNetease) {
      return Track(
        sourceTrackId: video.id.toString(),
        sourceId: 'netease',
        title: video.title,
        artist: video.author,
        album: video.description,
        coverUrl: video.pic,
        durationText: video.duration,
        uniqueId: video.uniqueId,
        extra: {
          'neteaseId': video.id,
        },
      );
    }
    if (video.isGdStudio) {
      return Track(
        sourceTrackId: video.id.toString(),
        sourceId: 'gdstudio',
        title: video.title,
        artist: video.author,
        album: video.description,
        coverUrl: video.pic,
        durationText: video.duration,
        uniqueId: video.uniqueId,
        extra: {
          'gdstudioBvid': video.bvid, // "source:trackId:lyricId"
        },
      );
    }
    return Track(
      sourceTrackId: video.bvid,
      sourceId: 'bilibili',
      title: video.title,
      artist: video.author,
      coverUrl: video.pic,
      durationText: video.duration,
      uniqueId: video.uniqueId,
      extra: {
        'bvid': video.bvid,
        'aid': video.id,
        'mid': video.mid,
        'play': video.play,
        'danmaku': video.danmaku,
        'description': video.description,
        'arcurl': video.arcurl,
      },
    );
  }

  /// Bridge: convert back to SearchVideoModel for gradual migration.
  SearchVideoModel toSearchVideoModel() {
    if (sourceId == 'netease') {
      return SearchVideoModel(
        id: extra['neteaseId'] as int? ?? int.tryParse(sourceTrackId) ?? 0,
        author: artist,
        title: title,
        description: album,
        pic: coverUrl,
        duration: durationText,
        source: MusicSource.netease,
      );
    }
    if (sourceId == 'gdstudio') {
      return SearchVideoModel(
        id: int.tryParse(sourceTrackId) ?? 0,
        author: artist,
        title: title,
        description: album,
        pic: coverUrl,
        duration: durationText,
        bvid: extra['gdstudioBvid'] as String? ?? '',
        source: MusicSource.gdstudio,
      );
    }
    return SearchVideoModel(
      id: extra['aid'] as int? ?? 0,
      author: artist,
      mid: extra['mid'] as int? ?? 0,
      title: title,
      description: extra['description'] as String? ?? '',
      pic: coverUrl,
      play: extra['play'] as int? ?? 0,
      danmaku: extra['danmaku'] as int? ?? 0,
      duration: durationText,
      bvid: extra['bvid'] as String? ?? sourceTrackId,
      arcurl: extra['arcurl'] as String? ?? '',
      source: MusicSource.bilibili,
    );
  }
}
