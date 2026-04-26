import 'package:get/get.dart';

import '../../core/crypto/aurora_eid.dart';
import '../../core/crypto/buvid.dart';
import '../../core/http/http_client.dart';
import '../../core/services/update_service.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/login/user_info_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/local_playlist_service.dart';
import '../player/player_controller.dart';
import '../music_discovery/music_discovery_controller.dart';
import '../playlist/playlist_controller.dart';
import '../profile/profile_controller.dart';
import '../search/search_controller.dart' as app;

class HomeController extends GetxController {
  // Bootstrap state
  final isBootstrapped = false.obs;

  // Bilibili login state
  final isLoggedIn = false.obs;
  final userInfo = Rxn<UserInfoModel>();

  final _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    refreshLoginStatus();
    _initializeControllers();
    _bootstrapAndPlay();
  }

  Future<void> _bootstrapAndPlay() async {
    try {
      await BuvidUtil.getBuvid();
      await BuvidUtil.activate();
      await HttpClient.instance.ensureVcDomainCookies();

      if (_storage.isLoggedIn && _storage.userMid != null) {
        final mid = _storage.userMid!;
        final auroraEid = AuroraEid.generate(int.tryParse(mid) ?? 0);
        HttpClient.instance.setAuthHeaders(mid: mid, auroraEid: auroraEid);
      }
    } catch (_) {}

    isBootstrapped.value = true;

    _autoPlayFromMode();

    Future.delayed(const Duration(seconds: 2), () {
      UpdateService.checkAndNotify();
    });
  }

  void _autoPlayFromMode() {
    final playerCtrl = Get.find<PlayerController>();
    if (playerCtrl.queue.isNotEmpty) return;

    final playlistService = Get.find<LocalPlaylistService>();
    if (playlistService.playlists.isEmpty) return;

    final first = playlistService.playlists.first;
    if (first.trackCount == 0) return;

    playerCtrl.playAllFromList(first.tracks);
  }

  void _initializeControllers() {
    Get.put(PlaylistController());
    if (!Get.isRegistered<app.SearchController>()) {
      Get.put(app.SearchController());
    }
    Get.lazyPut(() => MusicDiscoveryController());
    Get.lazyPut(() => ProfileController());
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
