import '../search/search_video_model.dart';

class NeteasePlaylistBrief {
  final int id;
  final String name;
  final String coverUrl;
  final int playCount;

  NeteasePlaylistBrief({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.playCount,
  });
}

class NeteasePlaylistDetail {
  final int id;
  final String name;
  final String coverUrl;
  final String description;
  final int playCount;
  final int trackCount;
  final String creatorName;
  final List<SearchVideoModel> tracks;

  NeteasePlaylistDetail({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.description,
    required this.playCount,
    required this.trackCount,
    required this.creatorName,
    required this.tracks,
  });
}

class NeteasePlaylistCategory {
  final String name;
  final bool hot;
  final int category;

  NeteasePlaylistCategory({
    required this.name,
    required this.hot,
    required this.category,
  });
}

class NeteasePlaylistSearchResult {
  final List<NeteasePlaylistBrief> playlists;
  final int playlistCount;

  NeteasePlaylistSearchResult(
      {required this.playlists, required this.playlistCount});
}
