import 'dart:developer';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/browse_models.dart';
import '../../data/models/music/hot_playlist_model.dart';
import '../../data/sources/music_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';

class MusicDiscoveryController extends GetxController {
  final _registry = Get.find<MusicSourceRegistry>();

  final curatedPlaylists = <PlaylistBrief>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await _loadCuratedPlaylists();
    } catch (e) {
      log('Music discovery load error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadCuratedPlaylists() async {
    try {
      final sources = _registry.getSourcesWithCapability<PlaylistCapability>();
      if (sources.isNotEmpty) {
        final playlists = await sources.first.getHotPlaylists(limit: 12);
        curatedPlaylists.assignAll(playlists.map((p) => PlaylistBrief(
              id: p.id,
              sourceId: sources.first.sourceId,
              name: p.name,
              coverUrl: p.coverUrl,
              playCount: p.playCount,
            )));
      }
    } catch (e) {
      log('Load curated playlists error: $e');
    }
  }

  void navigateToPlaylist(PlaylistBrief playlist) {
    final menuId = int.tryParse(playlist.id) ?? 0;
    if (menuId <= 0) return;
    Get.toNamed(
      AppRoutes.audioPlaylistDetail,
      arguments: HotPlaylistModel(
        menuId: menuId,
        title: playlist.name,
        cover: playlist.coverUrl,
        playCount: playlist.playCount,
        intro: '',
      ),
    );
  }
}
