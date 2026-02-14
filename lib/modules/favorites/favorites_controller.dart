import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/user/fav_folder_model.dart';
import '../../data/repositories/user_repository.dart';

class FavoritesController extends GetxController {
  final _repo = Get.find<UserRepository>();
  final _storage = Get.find<StorageService>();

  final folders = <FavFolderModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    final mid = int.tryParse(_storage.userMid ?? '') ?? 0;
    if (mid == 0) {
      isLoading.value = false;
      return;
    }
    final result = await _repo.getFavFolders(upMid: mid);
    folders.assignAll(result);
    isLoading.value = false;
  }

  void openFolder(FavFolderModel folder) {
    Get.toNamed(
      AppRoutes.favoriteDetail,
      arguments: {'mediaId': folder.id, 'title': folder.title},
    );
  }
}
