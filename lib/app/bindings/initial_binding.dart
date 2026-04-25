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
import '../../data/providers/gdstudio_provider.dart';
import '../../data/repositories/gdstudio_repository.dart';
import '../../data/services/local_playlist_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/sources/bilibili_source_adapter.dart';
import '../../data/sources/gdstudio_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
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
    Get.lazyPut(() => GdStudioProvider(), fenix: true);

    // Repositories
    Get.lazyPut(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => SearchRepository(), fenix: true);
    Get.lazyPut(() => PlayerRepository(), fenix: true);
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => MusicRepository(), fenix: true);
    Get.lazyPut(() => LyricsRepository(), fenix: true);
    Get.lazyPut(() => GdStudioRepository(), fenix: true);

    // Services
    Get.lazyPut(() => LocalPlaylistService()..init(), fenix: true);
    Get.lazyPut(() => UserProfileService(), fenix: true);

    // Music Source Registry (order determines search/fallback priority)
    final registry = MusicSourceRegistry();
    registry.register(GdStudioSourceAdapter());
    registry.register(BilibiliSourceAdapter());
    Get.put(registry, permanent: true);

    // Global persistent controller
    Get.put(PlayerController(), permanent: true);
  }
}
