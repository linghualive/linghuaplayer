import 'search/search_video_model.dart';

/// Generic playlist summary, replacing NeteasePlaylistBrief / HotPlaylistModel.
class PlaylistBrief {
  final String id;
  final String sourceId;
  final String name;
  final String coverUrl;
  final int playCount;

  PlaylistBrief({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.coverUrl,
    this.playCount = 0,
  });
}

/// Generic playlist detail.
class PlaylistDetail {
  final String id;
  final String sourceId;
  final String name;
  final String coverUrl;
  final String description;
  final int playCount;
  final int trackCount;
  final String creatorName;
  final List<SearchVideoModel> tracks;

  PlaylistDetail({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.coverUrl,
    this.description = '',
    this.playCount = 0,
    this.trackCount = 0,
    this.creatorName = '',
    required this.tracks,
  });
}

/// Generic artist summary.
class ArtistBrief {
  final String id;
  final String sourceId;
  final String name;
  final String picUrl;
  final int musicSize;
  final int albumSize;

  ArtistBrief({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.picUrl,
    this.musicSize = 0,
    this.albumSize = 0,
  });
}

/// Generic artist detail.
class ArtistDetail {
  final String id;
  final String sourceId;
  final String name;
  final String picUrl;
  final String briefDesc;
  final int musicSize;
  final int albumSize;
  final List<SearchVideoModel> hotSongs;

  ArtistDetail({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.picUrl,
    this.briefDesc = '',
    this.musicSize = 0,
    this.albumSize = 0,
    required this.hotSongs,
  });
}

/// Generic album summary.
class AlbumBrief {
  final String id;
  final String sourceId;
  final String name;
  final String picUrl;
  final String artistName;
  final int publishTime;
  final int size;

  AlbumBrief({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.picUrl,
    this.artistName = '',
    this.publishTime = 0,
    this.size = 0,
  });
}

/// Generic album detail.
class AlbumDetail {
  final String id;
  final String sourceId;
  final String name;
  final String picUrl;
  final String artistName;
  final int publishTime;
  final String description;
  final List<SearchVideoModel> tracks;

  AlbumDetail({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.picUrl,
    this.artistName = '',
    this.publishTime = 0,
    this.description = '',
    required this.tracks,
  });
}

/// Generic toplist item.
class ToplistItem {
  final String id;
  final String sourceId;
  final String name;
  final String coverUrl;
  final String updateFrequency;
  final List<String> trackPreviews;

  ToplistItem({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.coverUrl,
    this.updateFrequency = '',
    this.trackPreviews = const [],
  });
}

/// Generic search result container.
class SearchResult {
  final List<SearchVideoModel> tracks;
  final bool hasMore;
  final int totalCount;

  SearchResult({
    required this.tracks,
    this.hasMore = false,
    this.totalCount = 0,
  });
}

/// Hot search keyword.
class HotKeyword {
  final String keyword;
  final String displayName;
  final String? iconUrl;
  final int position;

  HotKeyword({
    required this.keyword,
    this.displayName = '',
    this.iconUrl,
    this.position = 0,
  });
}
