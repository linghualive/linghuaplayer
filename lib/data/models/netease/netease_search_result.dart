import '../search/search_video_model.dart';

class NeteaseSearchResult {
  final List<SearchVideoModel> songs;
  final int songCount;

  NeteaseSearchResult({required this.songs, required this.songCount});

  bool get hasMore => songs.isNotEmpty;
}
