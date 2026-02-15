import 'package:get/get.dart';

import '../../data/models/user/history_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/utils/app_toast.dart';
import '../player/player_controller.dart';

class WatchHistoryController extends GetxController {
  final _repo = Get.find<UserRepository>();

  final videos = <HistoryModel>[].obs;
  final isLoading = true.obs;
  final hasMore = true.obs;

  int _cursorMax = 0;
  int _cursorViewAt = 0;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    _cursorMax = 0;
    _cursorViewAt = 0;
    final result = await _repo.getHistoryCursor();
    videos.assignAll(result.items);
    _cursorMax = result.cursor;
    _cursorViewAt = result.viewAt;
    hasMore.value = result.items.isNotEmpty && _cursorMax > 0;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value) return;
    final result = await _repo.getHistoryCursor(
      max: _cursorMax,
      viewAt: _cursorViewAt,
    );
    videos.addAll(result.items);
    _cursorMax = result.cursor;
    _cursorViewAt = result.viewAt;
    hasMore.value = result.items.isNotEmpty && _cursorMax > 0;
  }

  Future<void> deleteItem(int index) async {
    final video = videos[index];
    final kid = '${video.business}_${video.kid}';
    final success = await _repo.deleteHistory(kid);
    if (success) {
      videos.removeAt(index);
    } else {
      AppToast.error('Failed to delete');
    }
  }

  Future<void> clearAll() async {
    final success = await _repo.clearHistory();
    if (success) {
      videos.clear();
    } else {
      AppToast.error('Failed to clear');
    }
  }

  void playVideo(HistoryModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }
}
