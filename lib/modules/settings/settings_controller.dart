import 'package:get/get.dart';

import '../../app/theme/theme_controller.dart';
import '../../core/storage/storage_service.dart';
import '../recommend/recommend_controller.dart';

class SettingsController extends GetxController {
  final themeCtrl = Get.find<ThemeController>();
  final _storage = Get.find<StorageService>();

  final gridColumns = 2.obs;
  final enableVideo = false.obs;

  @override
  void onInit() {
    super.onInit();
    gridColumns.value = _storage.customRows;
    enableVideo.value = _storage.enableVideo;
  }

  void setEnableVideo(bool value) {
    enableVideo.value = value;
    _storage.enableVideo = value;
  }

  void setGridColumns(int columns) {
    gridColumns.value = columns;
    _storage.customRows = columns;
    if (Get.isRegistered<RecommendController>()) {
      Get.find<RecommendController>().crossAxisCount.value = columns;
    }
  }
}
