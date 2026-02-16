import 'package:get/get.dart';

import '../../data/models/user/fav_resource_model.dart';
import '../../data/repositories/user_repository.dart';
import '../player/player_controller.dart';

class FavoriteDetailController extends GetxController {
  final _repo = Get.find<UserRepository>();

  final videos = <FavResourceModel>[].obs;
  final isLoading = true.obs;
  final hasMore = true.obs;
  final _page = 1.obs;

  late final int mediaId;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    mediaId = args['mediaId'] as int;
    title = args['title'] as String;
    loadVideos();
  }

  Future<void> loadVideos() async {
    isLoading.value = true;
    _page.value = 1;
    final result = await _repo.getFavResources(mediaId: mediaId, pn: 1);
    videos.assignAll(result.items);
    hasMore.value = result.hasMore;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value) return;
    _page.value++;
    final result =
        await _repo.getFavResources(mediaId: mediaId, pn: _page.value);
    videos.addAll(result.items);
    hasMore.value = result.hasMore;
  }

  void playVideo(FavResourceModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }

  void playAll() {
    if (videos.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(videos.first.toSearchVideoModel());
    if (videos.length > 1) {
      playerCtrl.addAllToQueue(
        videos.sublist(1).map((v) => v.toSearchVideoModel()).toList(),
      );
    }
  }

  void addAllToQueue() {
    if (videos.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.addAllToQueue(
      videos.map((v) => v.toSearchVideoModel()).toList(),
    );
  }
}
