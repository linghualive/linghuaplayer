import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/login/user_info_model.dart';
import '../../data/repositories/auth_repository.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;
  final isLoggedIn = false.obs;
  final userInfo = Rxn<UserInfoModel>();

  final _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    refreshLoginStatus();
  }

  void onTabChanged(int index) {
    currentIndex.value = index;
  }

  void refreshLoginStatus() {
    isLoggedIn.value = _storage.isLoggedIn;
    final cached = _storage.getUserInfo();
    if (cached != null) {
      userInfo.value = UserInfoModel.fromJson(cached);
    }
  }

  Future<void> logout() async {
    final authRepo = Get.find<AuthRepository>();
    await authRepo.logout();
    isLoggedIn.value = false;
    userInfo.value = null;
  }
}
