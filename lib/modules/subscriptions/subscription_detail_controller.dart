import 'package:get/get.dart';

import '../../data/models/user/sub_resource_model.dart';
import '../../data/repositories/user_repository.dart';
import '../player/player_controller.dart';

class SubscriptionDetailController extends GetxController {
  final _repo = Get.find<UserRepository>();

  final videos = <SubResourceModel>[].obs;
  final isLoading = true.obs;
  final hasMore = true.obs;
  final _page = 1.obs;

  late final int seasonId;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    seasonId = args['seasonId'] as int;
    title = args['title'] as String;
    loadVideos();
  }

  Future<void> loadVideos() async {
    isLoading.value = true;
    _page.value = 1;
    final result = await _repo.getSubSeasonVideos(seasonId: seasonId, pn: 1);
    videos.assignAll(result.items);
    hasMore.value = result.hasMore;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value) return;
    _page.value++;
    final result =
        await _repo.getSubSeasonVideos(seasonId: seasonId, pn: _page.value);
    videos.addAll(result.items);
    hasMore.value = result.hasMore;
  }

  void playVideo(SubResourceModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }
}
