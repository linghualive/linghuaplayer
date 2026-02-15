import 'package:get/get.dart';

import '../../data/models/user/watch_later_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/utils/app_toast.dart';
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
      AppToast.error('删除失败');
    }
  }

  Future<void> clearAll() async {
    final success = await _repo.clearWatchLater();
    if (success) {
      videos.clear();
    } else {
      AppToast.error('清空失败');
    }
  }

  void playVideo(WatchLaterModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }

  void playAll() {
    if (videos.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    // Play the first video
    playerCtrl.playFromSearch(videos.first.toSearchVideoModel());
    // Add the rest to queue
    for (var i = 1; i < videos.length; i++) {
      playerCtrl.addToQueueSilent(videos[i].toSearchVideoModel());
    }
  }
}
