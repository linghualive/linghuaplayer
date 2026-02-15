import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/theme_controller.dart';
import '../../core/services/update_service.dart';
import '../../core/storage/storage_service.dart';

class SettingsController extends GetxController {
  final themeCtrl = Get.find<ThemeController>();
  final _storage = Get.find<StorageService>();

  final enableVideo = false.obs;
  final appVersion = ''.obs;
  final isCheckingUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    enableVideo.value = _storage.enableVideo;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
  }

  void setEnableVideo(bool value) {
    enableVideo.value = value;
    _storage.enableVideo = value;
  }

  Future<void> checkForUpdate() async {
    isCheckingUpdate.value = true;
    await UpdateService.manualCheck();
    isCheckingUpdate.value = false;
  }
}
