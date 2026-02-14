import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/providers/login_provider.dart';
import '../../data/providers/search_provider.dart';
import '../../data/providers/player_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/recommend_provider.dart';
import '../../data/repositories/recommend_repository.dart';
import '../../modules/player/player_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Providers
    Get.lazyPut(() => LoginProvider(), fenix: true);
    Get.lazyPut(() => SearchProvider(), fenix: true);
    Get.lazyPut(() => PlayerProvider(), fenix: true);
    Get.lazyPut(() => UserProvider(), fenix: true);
    Get.lazyPut(() => RecommendProvider(), fenix: true);

    // Repositories
    Get.lazyPut(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => SearchRepository(), fenix: true);
    Get.lazyPut(() => PlayerRepository(), fenix: true);
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => RecommendRepository(), fenix: true);

    // Global persistent controller
    Get.put(PlayerController(), permanent: true);
  }
}
