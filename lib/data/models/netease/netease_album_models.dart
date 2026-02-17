import '../search/search_video_model.dart';

class NeteaseAlbumBrief {
  final int id;
  final String name;
  final String picUrl;
  final String artistName;
  final int publishTime;
  final int size;

  NeteaseAlbumBrief({
    required this.id,
    required this.name,
    required this.picUrl,
    required this.artistName,
    required this.publishTime,
    required this.size,
  });
}

class NeteaseAlbumDetail {
  final int id;
  final String name;
  final String picUrl;
  final String artistName;
  final int publishTime;
  final String description;
  final List<SearchVideoModel> tracks;

  NeteaseAlbumDetail({
    required this.id,
    required this.name,
    required this.picUrl,
    required this.artistName,
    required this.publishTime,
    required this.description,
    required this.tracks,
  });
}

class NeteaseAlbumSearchResult {
  final List<NeteaseAlbumBrief> albums;
  final int albumCount;

  NeteaseAlbumSearchResult({required this.albums, required this.albumCount});
}
