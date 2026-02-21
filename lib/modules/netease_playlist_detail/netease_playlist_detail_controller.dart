import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/services/local_playlist_service.dart';
import '../../shared/utils/app_toast.dart';
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

  /// Check if this playlist is already imported locally.
  bool get isImported {
    final service = Get.find<LocalPlaylistService>();
    return service.findByRemoteId('netease', playlistId.toString()) != null;
  }

  /// Import this playlist to local collection, or update if already imported.
  void importToLocal() {
    final d = detail.value;
    if (d == null || tracks.isEmpty) return;

    final service = Get.find<LocalPlaylistService>();
    final existing = service.findByRemoteId('netease', playlistId.toString());

    if (existing != null) {
      service.refreshPlaylist(existing.id, tracks);
      AppToast.show('歌单已更新');
    } else {
      service.importPlaylist(
        name: d.name,
        coverUrl: d.coverUrl,
        sourceTag: 'netease',
        remoteId: playlistId.toString(),
        tracks: tracks,
        creatorName: d.creatorName,
        description: d.description,
      );
      AppToast.show('已收藏到歌单');
    }
  }
}
