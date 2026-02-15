import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/http/netease_http_client.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/login/netease_user_info_model.dart';
import '../../data/models/login/user_info_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../desktop/music_discovery/desktop_music_discovery_page.dart';
import '../music_discovery/music_discovery_controller.dart';
import '../music_discovery/music_discovery_page.dart';
import '../playlist/playlist_controller.dart';
import '../playlist/playlist_page.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_page.dart';
import '../subscriptions/subscriptions_controller.dart';
import '../subscriptions/subscriptions_page.dart';

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

  // Pages list for desktop navigation
  late final List<Widget> pages;

  // Get current page based on selected index
  Widget get currentPage => pages[selectedIndex.value];

  // Auth service getter for desktop navigation
  AuthService get authService => AuthService(
    isLoggedIn: isLoggedIn,
    currentUser: userInfo,
  );

  @override
  void onInit() {
    super.onInit();
    refreshLoginStatus();
    _initializeControllers();
    _initializePages();
  }

  void _initializePages() {
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    if (isDesktop) {
      pages = [
        const DesktopMusicDiscoveryPage(),
        const SubscriptionsPage(), // Video page - TODO: Create desktop version
        const PlaylistPage(),      // Discover page - TODO: Create desktop version
        const ProfilePage(),       // Library/Playlists page - TODO: Create desktop version
      ];
    } else {
      pages = [
        const MusicDiscoveryPage(),
        const SubscriptionsPage(),
        const PlaylistPage(),
        const ProfilePage(),
      ];
    }
  }

  void _initializeControllers() {
    // Ensure sub-controllers are created
    Get.lazyPut(() => MusicDiscoveryController());
    Get.lazyPut(() => PlaylistController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => SubscriptionsController());
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

// Simple auth service wrapper for desktop navigation
class AuthService {
  final RxBool isLoggedIn;
  final Rxn<UserInfoModel> currentUser;

  AuthService({
    required this.isLoggedIn,
    required this.currentUser,
  });
}