import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/crypto/aurora_eid.dart';
import '../../core/crypto/buvid.dart';
import '../../core/http/http_client.dart';
import '../../core/storage/storage_service.dart';

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

      // 2. Restore auth state if logged in
      if (_storage.isLoggedIn && _storage.userMid != null) {
        final mid = _storage.userMid!;
        final auroraEid = AuroraEid.generate(int.tryParse(mid) ?? 0);
        HttpClient.instance.setAuthHeaders(
          mid: mid,
          auroraEid: auroraEid,
        );
      }
    } catch (_) {
      // Non-fatal initialization errors
    }

    // Navigate to home
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(AppRoutes.home);
  }
}
