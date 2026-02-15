import 'package:get/get.dart';

import '../../core/http/netease_http_client.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/login/netease_user_info_model.dart';
import '../../data/models/login/user_info_model.dart';
import '../../data/repositories/auth_repository.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  // Bilibili login state
  final isLoggedIn = false.obs;
  final userInfo = Rxn<UserInfoModel>();

  // NetEase login state
  final isNeteaseLoggedIn = false.obs;
  final neteaseUserInfo = Rxn<NeteaseUserInfoModel>();

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
    // Bilibili
    isLoggedIn.value = _storage.isLoggedIn;
    final cached = _storage.getUserInfo();
    if (cached != null) {
      userInfo.value = UserInfoModel.fromJson(cached);
    }

    // NetEase
    isNeteaseLoggedIn.value = _storage.isNeteaseLoggedIn;
    final neteaseCached = _storage.getNeteaseUserInfo();
    if (neteaseCached != null) {
      neteaseUserInfo.value = NeteaseUserInfoModel.fromJson(neteaseCached);
    } else {
      neteaseUserInfo.value = null;
    }
  }

  Future<void> logout() async {
    final authRepo = Get.find<AuthRepository>();
    await authRepo.logout();
    isLoggedIn.value = false;
    userInfo.value = null;
  }

  Future<void> logoutNetease() async {
    _storage.clearNeteaseAuth();
    await NeteaseHttpClient.instance.clearCookies();
    isNeteaseLoggedIn.value = false;
    neteaseUserInfo.value = null;
  }
}
