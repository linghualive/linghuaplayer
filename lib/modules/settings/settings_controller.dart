import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/theme_controller.dart';
import '../../core/services/update_service.dart';

class SettingsController extends GetxController {
  final themeCtrl = Get.find<ThemeController>();

  final appVersion = ''.obs;
  final isCheckingUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
  }

  Future<void> checkForUpdate() async {
    isCheckingUpdate.value = true;
    await UpdateService.manualCheck();
    isCheckingUpdate.value = false;
  }
}
