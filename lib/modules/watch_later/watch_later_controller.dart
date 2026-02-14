import 'package:get/get.dart';

import '../../data/models/user/watch_later_model.dart';
import '../../data/repositories/user_repository.dart';
import '../player/player_controller.dart';

class WatchLaterController extends GetxController {
  final _repo = Get.find<UserRepository>();

  final videos = <WatchLaterModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadList();
  }

  Future<void> loadList() async {
    isLoading.value = true;
    final result = await _repo.getWatchLaterList();
    videos.assignAll(result);
    isLoading.value = false;
  }

  Future<void> deleteItem(int index) async {
    final video = videos[index];
    final success = await _repo.deleteWatchLater(video.aid);
    if (success) {
      videos.removeAt(index);
    } else {
      Get.snackbar('Error', 'Failed to delete',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> clearAll() async {
    final success = await _repo.clearWatchLater();
    if (success) {
      videos.clear();
    } else {
      Get.snackbar('Error', 'Failed to clear',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void playVideo(WatchLaterModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }
}
