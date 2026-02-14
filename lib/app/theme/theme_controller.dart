import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import 'color_type.dart';

class ThemeController extends GetxController {
  final _storage = Get.find<StorageService>();

  final themeMode = 0.obs; // 0=system, 1=light, 2=dark
  final dynamicColor = false.obs;
  final customColorIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _storage.themeMode;
    dynamicColor.value = _storage.dynamicColor;
    customColorIndex.value = _storage.customColor;
  }

  ThemeMode get themeModeEnum {
    switch (themeMode.value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Color get seedColor {
    final index = customColorIndex.value;
    if (index >= 1 && index < colorThemeTypes.length) {
      return colorThemeTypes[index].color;
    }
    return colorThemeTypes[1].color; // Default bilibili pink
  }

  void setThemeMode(int mode) {
    themeMode.value = mode;
    _storage.themeMode = mode;
    Get.forceAppUpdate();
  }

  void setDynamicColor(bool enabled) {
    dynamicColor.value = enabled;
    _storage.dynamicColor = enabled;
    if (enabled) {
      customColorIndex.value = 0;
      _storage.customColor = 0;
    }
    Get.forceAppUpdate();
  }

  void setCustomColor(int index) {
    customColorIndex.value = index;
    _storage.customColor = index;
    if (index > 0) {
      dynamicColor.value = false;
      _storage.dynamicColor = false;
    }
    Get.forceAppUpdate();
  }
}
