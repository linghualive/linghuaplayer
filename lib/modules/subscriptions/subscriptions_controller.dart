import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/user/sub_folder_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/utils/app_toast.dart';

class SubscriptionsController extends GetxController {
  final _repo = Get.find<UserRepository>();
  final _storage = Get.find<StorageService>();

  final folders = <SubFolderModel>[].obs;
  final isLoading = true.obs;
  final hasMore = true.obs;
  final _page = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    _page.value = 1;
    final mid = int.tryParse(_storage.userMid ?? '') ?? 0;
    if (mid == 0) {
      isLoading.value = false;
      return;
    }
    final result = await _repo.getSubFolders(upMid: mid, pn: 1);
    folders.assignAll(result.items);
    hasMore.value = result.hasMore;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value) return;
    final mid = int.tryParse(_storage.userMid ?? '') ?? 0;
    if (mid == 0) return;
    _page.value++;
    final result = await _repo.getSubFolders(upMid: mid, pn: _page.value);
    folders.addAll(result.items);
    hasMore.value = result.hasMore;
  }

  void openFolder(SubFolderModel folder) {
    Get.toNamed(
      AppRoutes.subscriptionDetail,
      arguments: {'seasonId': folder.id, 'title': folder.title},
    );
  }

  Future<void> cancelSub(SubFolderModel folder) async {
    final success = await _repo.cancelSub(folder.id);
    if (success) {
      folders.remove(folder);
      AppToast.show('已取消订阅');
    } else {
      AppToast.error('取消订阅失败');
    }
  }
}
