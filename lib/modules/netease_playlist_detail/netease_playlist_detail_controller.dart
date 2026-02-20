import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../player/player_controller.dart';

class NeteasePlaylistDetailController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();

  final tracks = <SearchVideoModel>[].obs;
  final detail = Rxn<NeteasePlaylistDetail>();
  final isLoading = true.obs;

  late final int playlistId;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is NeteasePlaylistBrief) {
      playlistId = args.id;
      title = args.name;
    } else if (args is int) {
      playlistId = args;
      title = '';
    } else if (args is Map) {
      playlistId = args['playlistId'] as int? ?? 0;
      title = args['title'] as String? ?? '';
    } else {
      playlistId = 0;
      title = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    print('[DEBUG] Loading playlist detail for id=$playlistId');
    try {
      final result = await _neteaseRepo.getPlaylistDetail(playlistId);
      print('[DEBUG] getPlaylistDetail result: ${result != null ? 'tracks=${result.tracks.length}' : 'null'}');
      if (result != null) {
        detail.value = result;
        tracks.assignAll(result.tracks);
      }
    } catch (e, st) {
      print('[DEBUG] Load netease playlist detail error: $e\n$st');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    await _loadData();
  }

  void playSong(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song, preferredSourceId: null);
  }

  void playAll() {
    if (tracks.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(tracks.first, preferredSourceId: null);
    for (int i = 1; i < tracks.length; i++) {
      playerCtrl.addToQueueSilent(tracks[i]);
    }
  }
}
