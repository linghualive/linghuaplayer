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
import '../../data/providers/qqmusic_provider.dart';
import '../../data/providers/gdstudio_provider.dart';
import '../../data/repositories/deepseek_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../../data/repositories/gdstudio_repository.dart';
import '../../data/services/recommendation_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/sources/bilibili_source_adapter.dart';
import '../../data/sources/gdstudio_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
import '../../data/sources/netease_source_adapter.dart';
import '../../data/sources/qqmusic_source_adapter.dart';
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
    Get.lazyPut(() => QqMusicProvider(), fenix: true);
    Get.lazyPut(() => GdStudioProvider(), fenix: true);
    Get.lazyPut(() => DeepSeekProvider(), fenix: true);

    // Repositories
    Get.lazyPut(() => AuthRepository(), fenix: true);
    Get.lazyPut(() => SearchRepository(), fenix: true);
    Get.lazyPut(() => PlayerRepository(), fenix: true);
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => MusicRepository(), fenix: true);
    Get.lazyPut(() => LyricsRepository(), fenix: true);
    Get.lazyPut(() => NeteaseRepository(), fenix: true);
    Get.lazyPut(() => QqMusicRepository(), fenix: true);
    Get.lazyPut(() => GdStudioRepository(), fenix: true);
    Get.lazyPut(() => DeepSeekRepository(), fenix: true);

    // Services
    Get.lazyPut(() => RecommendationService(), fenix: true);
    Get.lazyPut(() => UserProfileService(), fenix: true);

    // Music Source Registry (order determines search/fallback priority)
    final registry = MusicSourceRegistry();
    registry.register(GdStudioSourceAdapter());
    registry.register(QqMusicSourceAdapter());
    registry.register(NeteaseSourceAdapter());
    registry.register(BilibiliSourceAdapter());
    Get.put(registry, permanent: true);

    // Global persistent controller
    Get.put(PlayerController(), permanent: true);
  }
}
