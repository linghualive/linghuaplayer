import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lightweight, non-blocking toast notifications.
/// Shows a small floating snackbar at the top that auto-dismisses
/// and does not interfere with touch operations.
/// Colors follow the current Material 3 theme.
class AppToast {
  static void show(String message) {
    if (Get.isSnackbarOpen) return;
    final cs = Get.theme.colorScheme;
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: cs.inverseSurface,
      messageText: Text(message, style: TextStyle(color: cs.onInverseSurface)),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  static void success(String message) {
    if (Get.isSnackbarOpen) return;
    final cs = Get.theme.colorScheme;
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: cs.inverseSurface,
      icon: Icon(Icons.check_circle_outline, color: cs.onInverseSurface),
      messageText: Text(message, style: TextStyle(color: cs.onInverseSurface)),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  static void error(String message) {
    if (Get.isSnackbarOpen) return;
    final cs = Get.theme.colorScheme;
    Get.rawSnackbar(
      message: message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: cs.error,
      icon: Icon(Icons.error_outline, color: cs.onError),
      messageText: Text(message, style: TextStyle(color: cs.onError)),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
