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
import '../../modules/favorites/favorites_page.dart';
import '../../modules/favorites/favorites_controller.dart';
import '../../modules/favorites/favorite_detail_page.dart';
import '../../modules/favorites/favorite_detail_controller.dart';
import '../../modules/subscriptions/subscriptions_page.dart';
import '../../modules/subscriptions/subscriptions_controller.dart';
import '../../modules/subscriptions/subscription_detail_page.dart';
import '../../modules/subscriptions/subscription_detail_controller.dart';
import '../../modules/watch_later/watch_later_page.dart';
import '../../modules/watch_later/watch_later_controller.dart';
import '../../modules/watch_history/watch_history_page.dart';
import '../../modules/watch_history/watch_history_controller.dart';
import '../../modules/settings/settings_page.dart';
import '../../modules/settings/settings_controller.dart';
import '../../modules/audio_playlist_detail/audio_playlist_detail_page.dart';
import '../../modules/audio_playlist_detail/audio_playlist_detail_controller.dart';
import '../../modules/music_ranking/music_ranking_page.dart';
import '../../modules/music_ranking/music_ranking_controller.dart';
import '../../modules/hot_playlists/hot_playlists_page.dart';
import '../../modules/hot_playlists/hot_playlists_controller.dart';
import '../../modules/webview/webview_page.dart';
import '../../modules/netease_playlist_detail/netease_playlist_detail_page.dart';
import '../../modules/netease_playlist_detail/netease_playlist_detail_controller.dart';
import '../../modules/netease_artist_detail/netease_artist_detail_page.dart';
import '../../modules/netease_artist_detail/netease_artist_detail_controller.dart';
import '../../modules/netease_album_detail/netease_album_detail_page.dart';
import '../../modules/netease_album_detail/netease_album_detail_controller.dart';
import '../../modules/netease_toplist/netease_toplist_page.dart';
import '../../modules/netease_toplist/netease_toplist_controller.dart';
import '../../modules/netease_hot_playlists/netease_hot_playlists_page.dart';
import '../../modules/netease_hot_playlists/netease_hot_playlists_controller.dart';
import '../../modules/qqmusic_playlist_detail/qqmusic_playlist_detail_page.dart';
import '../../modules/qqmusic_playlist_detail/qqmusic_playlist_detail_controller.dart';
import '../../modules/local_playlist_detail/local_playlist_detail_page.dart';
import '../../modules/local_playlist_detail/local_playlist_detail_controller.dart';
import '../../modules/qqmusic_artist_detail/qqmusic_artist_detail_page.dart';
import '../../modules/qqmusic_artist_detail/qqmusic_artist_detail_controller.dart';
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
        if (!Get.isRegistered<app.SearchController>()) {
          Get.put(app.SearchController());
        }
      }),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerPage(),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: BindingsBuilder(() {
        Get.put(FavoritesController());
      }),
    ),
    GetPage(
      name: AppRoutes.favoriteDetail,
      page: () => const FavoriteDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(FavoriteDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.subscriptions,
      page: () => const SubscriptionsPage(),
      binding: BindingsBuilder(() {
        Get.put(SubscriptionsController());
      }),
    ),
    GetPage(
      name: AppRoutes.subscriptionDetail,
      page: () => const SubscriptionDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(SubscriptionDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.watchLater,
      page: () => const WatchLaterPage(),
      binding: BindingsBuilder(() {
        Get.put(WatchLaterController());
      }),
    ),
    GetPage(
      name: AppRoutes.watchHistory,
      page: () => const WatchHistoryPage(),
      binding: BindingsBuilder(() {
        Get.put(WatchHistoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder(() {
        Get.put(SettingsController());
      }),
    ),
    GetPage(
      name: AppRoutes.audioPlaylistDetail,
      page: () => const AudioPlaylistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(AudioPlaylistDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.musicRanking,
      page: () => const MusicRankingPage(),
      binding: BindingsBuilder(() {
        Get.put(MusicRankingController());
      }),
    ),
    GetPage(
      name: AppRoutes.hotPlaylists,
      page: () => const HotPlaylistsPage(),
      binding: BindingsBuilder(() {
        Get.put(HotPlaylistsController());
      }),
    ),
    GetPage(
      name: AppRoutes.webview,
      page: () => const WebviewPage(),
    ),
    GetPage(
      name: AppRoutes.neteasePlaylistDetail,
      page: () => const NeteasePlaylistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(NeteasePlaylistDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.neteaseArtistDetail,
      page: () => const NeteaseArtistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(NeteaseArtistDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.neteaseAlbumDetail,
      page: () => const NeteaseAlbumDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(NeteaseAlbumDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.neteaseToplist,
      page: () => const NeteaseToplistPage(),
      binding: BindingsBuilder(() {
        Get.put(NeteaseToplistController());
      }),
    ),
    GetPage(
      name: AppRoutes.neteaseHotPlaylists,
      page: () => const NeteaseHotPlaylistsPage(),
      binding: BindingsBuilder(() {
        Get.put(NeteaseHotPlaylistsController());
      }),
    ),
    GetPage(
      name: AppRoutes.qqMusicPlaylistDetail,
      page: () => const QqMusicPlaylistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(QqMusicPlaylistDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.localPlaylistDetail,
      page: () => const LocalPlaylistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(LocalPlaylistDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.qqMusicArtistDetail,
      page: () => const QqMusicArtistDetailPage(),
      binding: BindingsBuilder(() {
        Get.put(QqMusicArtistDetailController());
      }),
    ),
  ];
}
