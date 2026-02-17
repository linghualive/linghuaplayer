import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/http/qqmusic_http_client.dart';

/// Low-level provider for QQ Music API calls.
///
/// Each method constructs the appropriate request and returns the raw Response.
/// No business logic or data transformation is performed here.
class QqMusicProvider {
  final QqMusicHttpClient _client;

  QqMusicProvider({QqMusicHttpClient? client})
      : _client = client ?? QqMusicHttpClient.instance;

  // ── Search ──────────────────────────────────────────

  /// Search songs by keyword.
  Future<Response> searchSongs(
    String keyword, {
    int limit = 30,
    int page = 1,
    int catZhida = 1,
  }) {
    return _client.yCommonRequest(
      '/soso/fcgi-bin/client_search_cp',
      {
        'w': keyword,
        'n': limit,
        'p': page,
        'catZhida': catZhida,
        'remoteplace': 'txt.yqq.song',
        'ct': 24,
        'qqmusic_ver': 1298,
        't': 0,
        'aggr': 1,
        'cr': 1,
        'lossless': 0,
        'flag_qc': 0,
      },
    );
  }

  /// Get hot search keywords.
  Future<Response> getHotkeys() {
    return _client.yCommonRequest(
      '/splcloud/fcgi-bin/gethotkey.fcg',
      {},
    );
  }

  /// Get search suggestions (smart box).
  Future<Response> getSmartbox(String keyword) {
    return _client.yCommonRequest(
      '/splcloud/fcgi-bin/smartbox_new.fcg',
      {'key': keyword},
    );
  }

  // ── Song Info & Playback ────────────────────────────

  /// Get song detail info.
  Future<Response> getSongInfo({String? songmid, int? songid}) {
    return _client.uCommonRequest({
      'songinfo': {
        'module': 'music.pf_song_detail_svr',
        'method': 'get_song_detail_yqq',
        'param': {
          'song_type': 0,
          'song_mid': songmid ?? '',
          'song_id': songid ?? 0,
        },
      },
    });
  }

  /// Get music play URL.
  Future<Response> getMusicPlayUrl(
    String songmid, {
    String quality = '128',
    String? mediaId,
  }) {
    final filename = QqMusicHttpClient.buildFilename(
      songmid, quality, mediaId: mediaId,
    );
    final guid = QqMusicHttpClient.generateGuid();

    return _client.uCommonRequest({
      'req_0': {
        'module': 'vkey.GetVkeyServer',
        'method': 'CgiGetVkey',
        'param': {
          'filename': [filename],
          'guid': guid,
          'songmid': [songmid],
          'songtype': [0],
          'uin': '0',
          'loginflag': 1,
          'platform': '20',
        },
      },
    });
  }

  // ── Lyrics ──────────────────────────────────────────

  /// Get lyrics for a song.
  Future<Response> getLyrics(String songmid) {
    return _client.yCommonRequest(
      '/lyric/fcgi-bin/fcg_query_lyric_new.fcg',
      {
        'songmid': songmid,
        'pcachetime': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ── Playlist ────────────────────────────────────────

  /// Get playlist category tags.
  Future<Response> getPlaylistCategories() {
    return _client.yCommonRequest(
      '/splcloud/fcgi-bin/fcg_get_diss_tag_conf.fcg',
      {},
    );
  }

  /// Get playlists by category.
  Future<Response> getPlaylistsByCategory({
    int categoryId = 10000000,
    int sortId = 5,
    int page = 0,
    int limit = 20,
  }) {
    return _client.yCommonRequest(
      '/splcloud/fcgi-bin/fcg_get_diss_by_tag.fcg',
      {
        'categoryId': categoryId,
        'sortId': sortId,
        'sin': page * limit,
        'ein': limit * (page + 1) - 1,
        'picmid': 1,
      },
    );
  }

  /// Get playlist detail with songs.
  Future<Response> getPlaylistDetail(String disstid) {
    return _client.yCommonRequest(
      '/qzone/fcg-bin/fcg_ucc_getcdinfo_byids_cp.fcg',
      {
        'disstid': disstid,
        'type': 1,
        'json': 1,
        'utf8': 1,
        'onlysong': 0,
        'new_format': 1,
      },
    );
  }

  // ── Toplist / Rankings ──────────────────────────────

  /// Get all toplists.
  Future<Response> getTopLists() {
    return _client.yCommonRequest(
      '/v8/fcg-bin/fcg_myqq_toplist.fcg',
      {
        'platform': 'h5',
        'needNewCode': 1,
      },
    );
  }

  /// Get toplist detail (ranking songs).
  Future<Response> getToplistDetail(
    int topId, {
    int limit = 100,
    int offset = 0,
    String? period,
  }) {
    return _client.uCommonRequest({
      'req_1': {
        'module': 'musicToplist.ToplistInfoServer',
        'method': 'GetDetail',
        'param': {
          'topId': topId,
          'offset': offset,
          'num': limit,
          if (period != null) 'period': period,
        },
      },
    });
  }

  // ── Singer ──────────────────────────────────────────

  /// Get singer list with filters.
  Future<Response> getSingerList({
    int area = -100,
    int sex = -100,
    int genre = -100,
    int index = -100,
    int page = 1,
  }) {
    final sin = (page - 1) * 80;
    return _client.uCommonRequest({
      'singerList': {
        'module': 'Music.SingerListServer',
        'method': 'get_singer_list',
        'param': {
          'area': area,
          'sex': sex,
          'genre': genre,
          'index': index,
          'sin': sin,
          'cur_page': page,
        },
      },
    });
  }

  /// Get singer hot songs.
  Future<Response> getSingerHotSongs(
    String singermid, {
    int limit = 30,
    int page = 1,
  }) {
    final sin = (page - 1) * limit;
    return _client.uCommonRequest({
      'singer': {
        'module': 'music.web_singer_info_svr',
        'method': 'get_singer_detail_info',
        'param': {
          'sort': 5,
          'singermid': singermid,
          'sin': sin,
          'num': limit,
        },
      },
    });
  }

  /// Get singer albums.
  Future<Response> getSingerAlbums(
    String singermid, {
    int limit = 30,
    int begin = 0,
  }) {
    return _client.uCommonRequest({
      'singer': {
        'module': 'music.musichallAlbum.AlbumListServer',
        'method': 'GetAlbumList',
        'param': {
          'sort': 5,
          'singermid': singermid,
          'begin': begin,
          'num': limit,
        },
      },
    });
  }

  // ── Album ───────────────────────────────────────────

  /// Get album detail info.
  Future<Response> getAlbumInfo(String albummid) {
    return _client.yCommonRequest(
      '/v8/fcg-bin/fcg_v8_album_info_cp.fcg',
      {'albummid': albummid},
    );
  }

  // ── Recommendation ─────────────────────────────────

  // ── Login ──────────────────────────────────────────────

  /// Step 1: Fetch QR code image (PNG bytes).
  Future<Response> getLoginQrCode() {
    return _client.loginDio.get(
      '${ApiConstants.qqMusicPtloginBaseUrl}${ApiConstants.qqMusicQrShow}',
      queryParameters: {
        'appid': ApiConstants.qqMusicAppId,
        'e': 2,
        'l': 'M',
        's': 3,
        'd': 72,
        'v': 4,
        'daid': ApiConstants.qqMusicDaid,
        'pt_3rd_aid': ApiConstants.qqMusicPt3rdAid,
        't': '${DateTime.now().millisecondsSinceEpoch / 1000}',
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Referer': 'https://xui.ptlogin2.qq.com/'},
      ),
    );
  }

  /// Step 2: Poll QR login status.
  Future<Response> pollQrLogin({
    required int ptqrtoken,
    required String qrsig,
  }) {
    return _client.loginDio.get(
      '${ApiConstants.qqMusicPtloginBaseUrl}${ApiConstants.qqMusicQrLogin}',
      queryParameters: {
        'u1': 'https://graph.qq.com/oauth2.0/login_jump',
        'ptqrtoken': ptqrtoken,
        'ptredirect': '0',
        'h': '1',
        't': '1',
        'g': '1',
        'from_ui': '1',
        'ptlang': '2052',
        'action': '0-0-${DateTime.now().millisecondsSinceEpoch}',
        'js_ver': '20102616',
        'js_type': '1',
        'pt_uistyle': '40',
        'aid': ApiConstants.qqMusicAppId,
        'daid': ApiConstants.qqMusicDaid,
        'pt_3rd_aid': ApiConstants.qqMusicPt3rdAid,
        'has_onekey': '1',
      },
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Referer': 'https://xui.ptlogin2.qq.com/',
          'Cookie': 'qrsig=$qrsig',
        },
      ),
    );
  }

  /// Step 3: check_sig — exchange ptsigx for p_skey cookie.
  Future<Response> checkSig({
    required String uin,
    required String sigx,
  }) {
    return _client.loginDio.get(
      'https://ssl.ptlogin2.graph.qq.com/check_sig',
      queryParameters: {
        'uin': uin,
        'pttype': '1',
        'service': 'ptqrlogin',
        'nodirect': '0',
        'ptsigx': sigx,
        's_url': 'https://graph.qq.com/oauth2.0/login_jump',
        'ptlang': '2052',
        'ptredirect': '100',
        'aid': ApiConstants.qqMusicAppId,
        'daid': ApiConstants.qqMusicDaid,
        'j_later': '0',
        'low_login_hour': '0',
        'regmaster': '0',
        'pt_login_type': '3',
        'pt_aid': '0',
        'pt_aaid': '16',
        'pt_light': '0',
        'pt_3rd_aid': ApiConstants.qqMusicPt3rdAid,
      },
      options: Options(
        headers: {'Referer': 'https://xui.ptlogin2.qq.com/'},
        followRedirects: false,
        validateStatus: (s) => s != null && s < 400,
      ),
    );
  }

  /// Step 4: OAuth authorize (POST with form data) to get auth code.
  Future<Response> oauthAuthorize({
    required String pSkey,
  }) {
    return _client.loginDio.post(
      '${ApiConstants.qqMusicGraphBaseUrl}${ApiConstants.qqMusicOauthAuthorize}',
      data: {
        'response_type': 'code',
        'client_id': '${ApiConstants.qqMusicClientId}',
        'redirect_uri':
            'https://y.qq.com/portal/wx_redirect.html?login_type=1&surl=https://y.qq.com/',
        'scope': 'get_user_info,get_app_friends',
        'state': 'state',
        'switch': '',
        'from_ptlogin': '1',
        'src': '1',
        'update_auth': '1',
        'openapi': '1010_1030',
        'g_tk': '${QqMusicHttpClient.getGtk(pSkey)}',
        'auth_time': '${DateTime.now().millisecondsSinceEpoch}',
        'ui': DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (s) => s != null && (s < 400 || s == 302),
      ),
    );
  }

  /// Step 5: QQ Music login via internal API with auth code.
  Future<Response> qqMusicLogin({required String code}) {
    return _client.uCommonRequest({
      'req': {
        'module': 'QQConnectLogin.LoginServer',
        'method': 'QQLogin',
        'param': {'code': code},
      },
    });
  }

  // ── User Playlists ──────────────────────────────────

  /// Get user playlists by UIN.
  Future<Response> getUserPlaylists(String uin) {
    return _client.yCommonRequest(
      '/rsc/fcgi-bin/fcg_user_created_diss',
      {
        'hostUin': 0,
        'hostuin': uin,
        'sin': 0,
        'size': 200,
      },
    );
  }

  /// Get aggregated homepage recommendations.
  Future<Response> getRecommend() {
    return _client.uCommonRequest({
      'recomPlaylist': {
        'module': 'playlist.HotRecommendServer',
        'method': 'get_hot_recommend',
        'param': {'async': 1, 'cmd': 2},
      },
      'toplist': {
        'module': 'musicToplist.ToplistInfoServer',
        'method': 'GetAll',
        'param': {},
      },
    });
  }
}
