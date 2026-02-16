import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/theme_controller.dart';
import '../../core/http/deepseek_http_client.dart';
import '../../core/services/update_service.dart';
import '../../core/storage/storage_service.dart';
import '../../data/repositories/deepseek_repository.dart';

class SettingsController extends GetxController {
  final themeCtrl = Get.find<ThemeController>();
  final _storage = Get.find<StorageService>();

  final enableVideo = false.obs;
  final appVersion = ''.obs;
  final isCheckingUpdate = false.obs;

  // DeepSeek
  final deepseekApiKey = ''.obs;
  final isValidatingKey = false.obs;

  @override
  void onInit() {
    super.onInit();
    enableVideo.value = _storage.enableVideo;
    deepseekApiKey.value = _storage.deepseekApiKey ?? '';
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

  Future<bool> setDeepseekApiKey(String key) async {
    if (key.isEmpty) {
      clearDeepseekApiKey();
      return true;
    }

    isValidatingKey.value = true;
    try {
      final repo = Get.find<DeepSeekRepository>();
      final valid = await repo.validateApiKey(key);
      if (valid) {
        _storage.deepseekApiKey = key;
        deepseekApiKey.value = key;
        DeepSeekHttpClient.instance.init(key);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isValidatingKey.value = false;
    }
  }

  void clearDeepseekApiKey() {
    _storage.deepseekApiKey = null;
    deepseekApiKey.value = '';
  }
}
