import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/recommend/rec_video_item_model.dart';
import '../../data/repositories/recommend_repository.dart';
import '../player/player_controller.dart';

class RecommendController extends GetxController {
  final _recRepo = Get.find<RecommendRepository>();
  final _storage = Get.find<StorageService>();

  final videoList = <RecVideoItemModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final crossAxisCount = 2.obs;

  int _freshIdx = 0;

  @override
  void onInit() {
    super.onInit();
    crossAxisCount.value = _storage.customRows;
    loadFeed();
  }

  Future<void> loadFeed() async {
    isLoading.value = true;
    _freshIdx = 0;
    try {
      final items = await _recRepo.getTopFeedRcmd(freshIdx: _freshIdx);
      videoList.assignAll(items);
      _freshIdx++;
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final items = await _recRepo.getTopFeedRcmd(
        freshIdx: _freshIdx,
        brush: _freshIdx + 1,
      );
      videoList.addAll(items);
      _freshIdx++;
    } catch (_) {}
    isLoadingMore.value = false;
  }

  void onVideoTap(RecVideoItemModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }

  void setGridColumns(int columns) {
    crossAxisCount.value = columns;
    _storage.customRows = columns;
  }
}
