import 'package:get/get.dart';

import '../../data/models/browse_models.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../../data/services/local_playlist_service.dart';
import '../../shared/utils/app_toast.dart';
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

  /// Check if this playlist is already imported locally.
  bool get isImported {
    final service = Get.find<LocalPlaylistService>();
    return service.findByRemoteId('qqmusic', disstid) != null;
  }

  /// Import this playlist to local collection, or update if already imported.
  void importToLocal() {
    final d = detail.value;
    if (d == null || tracks.isEmpty) return;

    final service = Get.find<LocalPlaylistService>();
    final existing = service.findByRemoteId('qqmusic', disstid);

    if (existing != null) {
      service.refreshPlaylist(existing.id, tracks);
      AppToast.show('歌单已更新');
    } else {
      service.importPlaylist(
        name: d.name,
        coverUrl: d.coverUrl,
        sourceTag: 'qqmusic',
        remoteId: disstid,
        tracks: tracks,
        creatorName: d.creatorName,
        description: d.description,
      );
      AppToast.show('已收藏到歌单');
    }
  }
}
