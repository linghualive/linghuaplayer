import 'package:get/get.dart';

import '../../modules/home/home_page.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/login/login_page.dart';
import '../../modules/login/login_controller.dart';
import '../../modules/player/player_page.dart';
import '../../modules/search/search_page.dart';
import '../../modules/search/search_controller.dart' as app;
import '../../modules/splash/splash_page.dart';
import '../../modules/splash/splash_controller.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: BindingsBuilder(() {
        Get.put(app.SearchController());
      }),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerPage(),
    ),
  ];
}
