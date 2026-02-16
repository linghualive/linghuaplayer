import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/http/netease_http_client.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/login/netease_user_info_model.dart';
import '../../data/models/login/user_info_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../discover/discover_controller.dart';
import '../player/player_home_tab.dart';
import '../playlist/playlist_controller.dart';
import '../playlist/playlist_page.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_page.dart';
import '../search/search_controller.dart' as app;
import '../search/search_page.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  // For desktop navigation
  final selectedIndex = 0.obs;

  // Bilibili login state
  final isLoggedIn = false.obs;
  final userInfo = Rxn<UserInfoModel>();

  // NetEase login state
  final isNeteaseLoggedIn = false.obs;
  final neteaseUserInfo = Rxn<NeteaseUserInfoModel>();

  final _storage = Get.find<StorageService>();

  // Pages list for navigation
  late final List<Widget> pages;

  @override
  void onInit() {
    super.onInit();
    refreshLoginStatus();
    _initializeControllers();
    _initializePages();
  }

  void _initializePages() {
    pages = [
      const PlayerHomeTab(),
      const SearchPage(isEmbedded: true),
      const PlaylistPage(),
      const ProfilePage(),
    ];
  }

  void _initializeControllers() {
    Get.put(PlaylistController());
    Get.put(DiscoverController());
    Get.put(ProfileController());
    if (!Get.isRegistered<app.SearchController>()) {
      Get.put(app.SearchController());
    }
  }

  void onTabChanged(int index) {
    currentIndex.value = index;
  }

  // For desktop navigation
  void onNavigationChanged(int index) {
    selectedIndex.value = index;
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
