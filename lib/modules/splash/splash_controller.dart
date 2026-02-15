import 'dart:developer';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/crypto/aurora_eid.dart';
import '../../core/crypto/buvid.dart';
import '../../core/http/http_client.dart';
import '../../core/services/update_service.dart';
import '../../core/storage/storage_service.dart';
import '../../data/repositories/netease_repository.dart';

class SplashController extends GetxController {
  final _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Get/activate BUVID
      await BuvidUtil.getBuvid();
      await BuvidUtil.activate();

      // 2. Restore Bilibili auth state if logged in
      if (_storage.isLoggedIn && _storage.userMid != null) {
        final mid = _storage.userMid!;
        final auroraEid = AuroraEid.generate(int.tryParse(mid) ?? 0);
        HttpClient.instance.setAuthHeaders(
          mid: mid,
          auroraEid: auroraEid,
        );
      }

      // 3. Verify NetEase session if logged in
      if (_storage.isNeteaseLoggedIn) {
        await _verifyNeteaseSession();
      }
    } catch (_) {
      // Non-fatal initialization errors
    }

    // Navigate to home
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(AppRoutes.home);

    // Check for updates after home loads (non-blocking)
    Future.delayed(const Duration(seconds: 2), () {
      UpdateService.checkAndNotify();
    });
  }

  Future<void> _verifyNeteaseSession() async {
    try {
      final neteaseRepo = Get.find<NeteaseRepository>();
      final accountInfo = await neteaseRepo.getAccountInfo();
      if (accountInfo == null) {
        // Session expired, clear login state
        log('NetEase session expired, clearing auth');
        _storage.clearNeteaseAuth();
      }
    } catch (e) {
      log('NetEase session verification error: $e');
      _storage.clearNeteaseAuth();
    }
  }
}
