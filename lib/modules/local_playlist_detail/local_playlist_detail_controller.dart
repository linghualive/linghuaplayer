import 'package:get/get.dart';

import '../../data/models/local_playlist_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/local_playlist_service.dart';
import '../../shared/utils/app_toast.dart';
import '../player/player_controller.dart';

class LocalPlaylistDetailController extends GetxController {
  final _playlistService = Get.find<LocalPlaylistService>();

  final playlist = Rxn<LocalPlaylist>();
  final tracks = <SearchVideoModel>[].obs;
  final isRefreshing = false.obs;

  late final String playlistId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      playlistId = args['playlistId'] as String? ?? '';
    } else if (args is String) {
      playlistId = args;
    } else {
      playlistId = '';
    }
    _loadData();
  }

  void _loadData() {
    final p = _playlistService.getPlaylist(playlistId);
    if (p == null) return;
    playlist.value = p;
    tracks.assignAll(p.tracks);
  }

  String get _preferredSourceId {
    switch (playlist.value?.sourceTag) {
      case 'bilibili':
        return 'bilibili';
      case 'netease':
        return 'netease';
      case 'qqmusic':
        return 'qqmusic';
      default:
        return 'gdstudio';
    }
  }

  void playSong(SearchVideoModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(song, preferredSourceId: _preferredSourceId);
  }

  void playAll() {
    if (tracks.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(tracks.first,
        preferredSourceId: _preferredSourceId);
    for (int i = 1; i < tracks.length; i++) {
      playerCtrl.addToQueueSilent(tracks[i]);
    }
  }

  void addAllToQueue() {
    if (tracks.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.addAllToQueue(tracks.toList());
  }

  void removeTrack(int index) {
    if (index < 0 || index >= tracks.length) return;
    final track = tracks[index];
    _playlistService.removeTrack(playlistId, track.uniqueId);
    tracks.removeAt(index);
    playlist.value = _playlistService.getPlaylist(playlistId);
  }

  Future<void> refreshFromRemote() async {
    final p = playlist.value;
    if (p == null || p.remoteId == null) return;

    isRefreshing.value = true;
    try {
      List<SearchVideoModel> newTracks = [];

      switch (p.sourceTag) {
        case 'bilibili':
          final repo = Get.find<UserRepository>();
          final mediaId = int.tryParse(p.remoteId!) ?? 0;
          if (mediaId > 0) {
            int page = 1;
            bool hasMore = true;
            while (hasMore) {
              final result =
                  await repo.getFavResources(mediaId: mediaId, pn: page, ps: 20);
              newTracks.addAll(result.items.map((e) => e.toSearchVideoModel()));
              hasMore = result.hasMore;
              page++;
            }
          }
          break;
        case 'netease':
          final repo = Get.find<NeteaseRepository>();
          final neteaseId = int.tryParse(p.remoteId!) ?? 0;
          if (neteaseId > 0) {
            final detail = await repo.getPlaylistDetail(neteaseId);
            if (detail != null) newTracks = detail.tracks;
          }
          break;
        case 'qqmusic':
          final repo = Get.find<QqMusicRepository>();
          final detail = await repo.getPlaylistDetail(p.remoteId!);
          if (detail != null) newTracks = detail.tracks;
          break;
      }

      if (newTracks.isNotEmpty) {
        _playlistService.refreshPlaylist(playlistId, newTracks);
        _loadData();
        AppToast.show('已刷新，共 ${newTracks.length} 首');
      } else {
        AppToast.show('未获取到新曲目');
      }
    } catch (e) {
      AppToast.error('刷新失败');
    }
    isRefreshing.value = false;
  }
}
