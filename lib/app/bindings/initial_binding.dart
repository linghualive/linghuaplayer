import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/lyrics_repository.dart';
import '../../data/providers/login_provider.dart';
import '../../data/providers/search_provider.dart';
import '../../data/providers/player_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/music_provider.dart';
import '../../data/providers/lyrics_provider.dart';
import '../../data/providers/deepseek_provider.dart';
import '../../data/providers/netease_provider.dart';
import '../../data/repositories/deepseek_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../../modules/player/player_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Providers
    Get.lazyPut(() => LoginProvider(), fenix: true);
    Get.lazyPut(() => SearchProvider(), fenix: true);
    Get.lazyPut(() => PlayerProvider(), fenix: true);
    Get.lazyPut(() => UserProvider(), fenix: true);
    Get.lazyPut(() => MusicProvider(), fenix: true);
    Get.lazyPut(() => LyricsProvider(), fenix: true);
    Get.lazyPut(() => NeteaseProvider(), fenix: true);
    Get.lazyPut(() => DeepSeekProvider(), fenix: true);

    // Repositories
    Get.lazyPut(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => SearchRepository(), fenix: true);
    Get.lazyPut(() => PlayerRepository(), fenix: true);
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => MusicRepository(), fenix: true);
    Get.lazyPut(() => LyricsRepository(), fenix: true);
    Get.lazyPut(() => NeteaseRepository(), fenix: true);
    Get.lazyPut(() => DeepSeekRepository(), fenix: true);

    // Global persistent controller
    Get.put(PlayerController(), permanent: true);
  }
}
