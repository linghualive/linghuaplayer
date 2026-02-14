class ApiConstants {
  static const String baseUrl = 'https://www.bilibili.com';
  static const String apiBaseUrl = 'https://api.bilibili.com';
  static const String tUrl = 'https://api.vc.bilibili.com';
  static const String appBaseUrl = 'https://app.bilibili.com';
  static const String passBaseUrl = 'https://passport.bilibili.com';
  static const String searchBaseUrl = 'https://s.search.bilibili.com';

  static const String appKey = '4409e2ce8ffd12b8';
  static const String appSec = '59b43e04ad6965f34319062b478f83dd';

  // WBI mixinKeyEncTab
  static const List<int> mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35,
    27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
    37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4,
    22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52,
  ];

  // AV/BV conversion constants
  static const int xorCode = 23442827791579;
  static const int maskCode = 2251799813685247;
  static const int maxAid = 1 << 51;
  static const int base = 58;
  static const String bvTable =
      'FcwAPNKTMug3GV5Lj7EJnHpWsx4tb8haYeviqBz6rkCy12mUSDQX9RdoZf';

  // API endpoints
  static const String fingerSpi = '/x/frontend/finger/spi';
  static const String buvidActivate = '/x/internal/gaia-gateway/ExClimbWuzhi';
  static const String navInfo = '/x/web-interface/nav';
  static const String navStat = '/x/web-interface/nav/stat';

  // Login endpoints
  static const String captcha =
      '/x/passport-login/captcha?source=main_web';
  static const String qrcodeGenerate =
      '/x/passport-login/web/qrcode/generate';
  static const String qrcodePoll =
      '/x/passport-login/web/qrcode/poll';
  static const String smsSend =
      '/x/passport-login/web/sms/send';
  static const String smsLogin =
      '/x/passport-login/web/login/sms';
  static const String webKey =
      '/x/passport-login/web/key';
  static const String webLogin =
      '/x/passport-login/web/login';

  // Recommendation endpoints
  static const String topFeedRcmd = '/x/web-interface/index/top/feed/rcmd';

  // Search endpoints
  static const String hotSearch = '/main/hotword';
  static const String searchSuggest = '/main/suggest';
  static const String searchByType = '/x/web-interface/wbi/search/type';
  static const String searchAll = '/x/web-interface/wbi/search/all/v2';

  // Player endpoints
  static const String pagelist = '/x/player/pagelist';
  static const String playUrl = '/x/player/wbi/playurl';

  // Favorites endpoints
  static const String favFolderList = '/x/v3/fav/folder/created/list';
  static const String favFolderListAll = '/x/v3/fav/folder/created/list-all';
  static const String favResourceList = '/x/v3/fav/resource/list';
  static const String favResourceDeal = '/x/v3/fav/resource/deal';
  static const String hasFavVideo = '/x/v2/fav/video/favoured';
  static const String addFavFolder = '/x/v3/fav/folder/add';
  static const String editFavFolder = '/x/v3/fav/folder/edit';

  // Subscriptions endpoints
  static const String subFolderList = '/x/v3/fav/folder/collected/list';
  static const String subSeasonList = '/x/space/fav/season/list';

  // Watch Later endpoints
  static const String watchLaterList = '/x/v2/history/toview';
  static const String watchLaterDel = '/x/v2/history/toview/del';
  static const String watchLaterClear = '/x/v2/history/toview/clear';

  // Watch History endpoints
  static const String historyCursor = '/x/web-interface/history/cursor';
  static const String historyDelete = '/x/v2/history/delete';
  static const String historyClear = '/x/v2/history/clear';

  // Audio/Music endpoints (base: www.bilibili.com)
  static const String audioHotPlaylists =
      '/audio/music-service-c/web/menu/hit';
  static const String audioPlaylistInfo =
      '/audio/music-service-c/web/menu/info';
  static const String audioPlaylistSongs =
      '/audio/music-service-c/web/song/of-menu';
  static const String audioSongInfo = '/audio/music-service-c/web/song/info';
  static const String audioUrl = '/audio/music-service-c/web/url';

  // Music Ranking endpoints (base: api.bilibili.com)
  static const String musicRankPeriods =
      '/x/copyright-music-publicity/toplist/all_period';
  static const String musicRankSongs =
      '/x/copyright-music-publicity/toplist/music_list';

  // MV List endpoint (base: api.bilibili.com)
  static const String mvList = '/x/mv/list';
}
