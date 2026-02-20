import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../player/player_controller.dart';

class NeteaseArtistDetailController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();

  final detail = Rxn<NeteaseArtistDetail>();
  final albums = <NeteaseAlbumBrief>[].obs;
  final isLoading = true.obs;

  late final int artistId;
  late final String artistName;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is NeteaseArtistBrief) {
      artistId = args.id;
      artistName = args.name;
    } else if (args is int) {
      artistId = args;
      artistName = '';
    } else {
      artistId = 0;
      artistName = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadDetail(),
        _loadAlbums(),
      ]);
    } catch (e) {
      log('Load artist detail error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadDetail() async {
    final result = await _neteaseRepo.getArtistDetail(artistId);
    if (result != null) {
      detail.value = result;
    }
  }

  Future<void> _loadAlbums() async {
    final result = await _neteaseRepo.getArtistAlbums(artistId);
    albums.assignAll(result);
  }

  Future<void> reload() async {
    await _loadData();
  }

  void playSong(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song, preferredSourceId: null);
  }

  void playAll() {
    final songs = detail.value?.hotSongs;
    if (songs == null || songs.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(songs.first, preferredSourceId: null);
    for (int i = 1; i < songs.length; i++) {
      playerCtrl.addToQueueSilent(songs[i]);
    }
  }
}
