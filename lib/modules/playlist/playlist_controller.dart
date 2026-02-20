import 'package:get/get.dart';

import '../../data/models/local_playlist_model.dart';
import '../../data/services/local_playlist_service.dart';

class PlaylistController extends GetxController {
  final _playlistService = Get.find<LocalPlaylistService>();

  final searchQuery = ''.obs;

  RxList<LocalPlaylist> get allPlaylists => _playlistService.playlists;

  List<LocalPlaylist> get filteredPlaylists {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return allPlaylists.toList();
    return allPlaylists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  void deletePlaylist(String id) {
    _playlistService.deletePlaylist(id);
  }

  void renamePlaylist(String id, String newName) {
    _playlistService.renamePlaylist(id, newName);
  }
}
