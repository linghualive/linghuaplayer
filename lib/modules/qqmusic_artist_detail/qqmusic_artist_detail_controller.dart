import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/browse_models.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../player/player_controller.dart';

class QqMusicArtistDetailController extends GetxController {
  final _qqMusicRepo = Get.find<QqMusicRepository>();

  final detail = Rxn<ArtistDetail>();
  final isLoading = true.obs;

  late final String singerMid;
  late final String singerName;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is QqMusicSingerBrief) {
      singerMid = args.singerMid;
      singerName = args.name;
    } else if (args is Map) {
      singerMid = (args['singerMid'] ?? '').toString();
      singerName = args['name'] as String? ?? '';
    } else if (args is String) {
      singerMid = args;
      singerName = '';
    } else {
      singerMid = '';
      singerName = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final result = await _qqMusicRepo.getArtistDetail(singerMid);
      if (result != null) {
        detail.value = result;
      }
    } catch (e) {
      log('Load QQ artist detail error: $e');
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
    final songs = detail.value?.hotSongs;
    if (songs == null || songs.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(songs.first, preferredSourceId: null);
    for (int i = 1; i < songs.length; i++) {
      playerCtrl.addToQueueSilent(songs[i]);
    }
  }
}
