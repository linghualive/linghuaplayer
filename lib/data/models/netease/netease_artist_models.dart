import '../search/search_video_model.dart';

class NeteaseArtistBrief {
  final int id;
  final String name;
  final String picUrl;
  final int musicSize;
  final int albumSize;

  NeteaseArtistBrief({
    required this.id,
    required this.name,
    required this.picUrl,
    required this.musicSize,
    required this.albumSize,
  });
}

class NeteaseArtistDetail {
  final int id;
  final String name;
  final String picUrl;
  final String briefDesc;
  final int musicSize;
  final int albumSize;
  final List<SearchVideoModel> hotSongs;

  NeteaseArtistDetail({
    required this.id,
    required this.name,
    required this.picUrl,
    required this.briefDesc,
    required this.musicSize,
    required this.albumSize,
    required this.hotSongs,
  });
}

class NeteaseArtistSearchResult {
  final List<NeteaseArtistBrief> artists;
  final int artistCount;

  NeteaseArtistSearchResult({required this.artists, required this.artistCount});
}
