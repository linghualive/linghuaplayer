import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/search_video_model.dart';
import '../player/player_controller.dart';

class WatchHistoryController extends GetxController {
  final _storage = Get.find<StorageService>();

  final videos = <SearchVideoModel>[].obs;
  final playedAtList = <int>[].obs;
  final isLoading = true.obs;
  final hasMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    final history = _storage.getPlayHistory();
    videos.clear();
    playedAtList.clear();
    for (final entry in history) {
      final videoJson = entry['video'] as Map<String, dynamic>?;
      if (videoJson == null) continue;
      videos.add(SearchVideoModel.fromJson(videoJson));
      playedAtList.add(entry['playedAt'] as int? ?? 0);
    }
    hasMore.value = false;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    // Local data is loaded at once, no pagination needed.
  }

  Future<void> deleteItem(int index) async {
    final video = videos[index];
    _storage.removePlayHistory(video.uniqueId);
    videos.removeAt(index);
    playedAtList.removeAt(index);
  }

  Future<void> clearAll() async {
    _storage.clearPlayHistory();
    videos.clear();
    playedAtList.clear();
  }

  void playVideo(SearchVideoModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video, preferredSourceId: null);
  }
}
