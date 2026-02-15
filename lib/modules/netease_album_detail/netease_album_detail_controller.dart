import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../player/player_controller.dart';

class NeteaseAlbumDetailController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();

  final detail = Rxn<NeteaseAlbumDetail>();
  final tracks = <SearchVideoModel>[].obs;
  final isLoading = true.obs;

  late final int albumId;
  late final String albumName;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is NeteaseAlbumBrief) {
      albumId = args.id;
      albumName = args.name;
    } else if (args is int) {
      albumId = args;
      albumName = '';
    } else {
      albumId = 0;
      albumName = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final result = await _neteaseRepo.getAlbumDetail(albumId);
      if (result != null) {
        detail.value = result;
        tracks.assignAll(result.tracks);
      }
    } catch (e) {
      log('Load album detail error: $e');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    await _loadData();
  }

  void playSong(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song);
  }

  void playAll() {
    if (tracks.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(tracks.first);
    for (int i = 1; i < tracks.length; i++) {
      playerCtrl.addToQueueSilent(tracks[i]);
    }
  }
}
