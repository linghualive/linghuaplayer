import 'package:get/get.dart';

import '../../data/models/browse_models.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../player/player_controller.dart';

class QqMusicPlaylistDetailController extends GetxController {
  final _qqMusicRepo = Get.find<QqMusicRepository>();

  final tracks = <SearchVideoModel>[].obs;
  final detail = Rxn<PlaylistDetail>();
  final isLoading = true.obs;

  late final String disstid;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      disstid = (args['disstid'] ?? '').toString();
      title = args['title'] as String? ?? '';
    } else if (args is String) {
      disstid = args;
      title = '';
    } else {
      disstid = '';
      title = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final result = await _qqMusicRepo.getPlaylistDetail(disstid);
      if (result != null) {
        detail.value = result;
        tracks.assignAll(result.tracks);
      }
    } catch (_) {}
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
