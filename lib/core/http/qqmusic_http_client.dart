import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/constants/api_constants.dart';

/// Quality info for QQ Music file naming.
class QualityInfo {
  final String prefix;
  final String extension;
  const QualityInfo(this.prefix, this.extension);
}

/// QQ Music direct HTTP client (no proxy).
///
/// Uses two Dio instances:
/// - `_yCommonDio` for `c.y.qq.com` (search, lyrics, playlist categories)
/// - `_uCommonDio` for `u.y.qq.com` (playback, details, recommendations)
class QqMusicHttpClient {
  static QqMusicHttpClient? _instance;
  late final Dio _yCommonDio;
  late final Dio _uCommonDio;
  late final PersistCookieJar cookieJar;

  static const _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';

  /// Quality mapping for play URL filename construction.
  static const qualityMap = {
    '128': QualityInfo('M500', '.mp3'),
    '320': QualityInfo('M800', '.mp3'),
    'm4a': QualityInfo('C400', '.m4a'),
    'ape': QualityInfo('A000', '.ape'),
    'flac': QualityInfo('F000', '.flac'),
  };

  String _loginUin = '0';
  int _gtk = 0;

  late final Dio _loginDio;
  late CookieJar _loginCookieJar;

  QqMusicHttpClient._();

  static QqMusicHttpClient get instance {
    _instance ??= QqMusicHttpClient._();
    return _instance!;
  }

  /// For testing: allow injecting a mock instance.
  static set instance(QqMusicHttpClient client) {
    _instance = client;
  }

  /// Whether the user is logged in.
  bool get isLoggedIn => _loginUin != '0' && _loginUin.isNotEmpty;

  /// Current login UIN.
  String get loginUin => _loginUin;

  /// Dio instance for login flow (ephemeral session).
  Dio get loginDio => _loginDio;

  /// Reset the ephemeral login cookie jar (for a fresh QR flow).
  void resetLoginCookies() {
    _loginCookieJar = CookieJar();
    _loginDio.interceptors.clear();
    _loginDio.interceptors.add(CookieManager(_loginCookieJar));
  }

  /// Get cookies from the login cookie jar for a given URL.
  Future<List<Cookie>> getLoginCookies(Uri uri) async {
    return _loginCookieJar.loadForRequest(uri);
  }

  /// hash33 algorithm: compute ptqrtoken from qrsig.
  static int hash33(String t) {
    int e = 0;
    for (int n = 0; n < t.length; n++) {
      e += (e << 5) + t.codeUnitAt(n);
    }
    return 2147483647 & e;
  }

  /// Compute g_tk (CSRF token) from p_skey.
  static int getGtk(String pSkey) {
    int hash = 5381;
    for (int i = 0; i < pSkey.length; i++) {
      hash += (hash << 5) + pSkey.codeUnitAt(i);
    }
    return hash & 0x7fffffff;
  }

  /// Generate a UUID v4 GUID.
  static String generateGuid() {
    final random = math.Random();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (match) {
        final r = (random.nextDouble() * 16).floor();
        final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    ).toUpperCase();
  }

  /// Build a play URL filename.
  ///
  /// e.g. `M500{songmid}{mediaId}.mp3` for 128kbps quality.
  static String buildFilename(String songmid, String quality, {String? mediaId}) {
    final info = qualityMap[quality] ?? qualityMap['128']!;
    return '${info.prefix}$songmid${mediaId ?? songmid}${info.extension}';
  }

  /// Common query parameters for all QQ Music requests.
  Map<String, dynamic> get _commonParams => {
    'g_tk': _gtk,
    'loginUin': _loginUin,
    'hostUin': 0,
    'inCharset': 'utf8',
    'outCharset': 'utf-8',
    'notice': 0,
    'platform': 'yqq.json',
    'needNewCode': 0,
  };

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final cookiePath = '${dir.path}/.qqmusic_cookies/';
    cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    _yCommonDio = Dio(BaseOptions(
      baseUrl: ApiConstants.qqMusicContentBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _userAgent,
        'Referer': '${ApiConstants.qqMusicContentBaseUrl}/',
      },
      contentType: Headers.formUrlEncodedContentType,
      // QQ Music API returns non-standard Content-Type, so use plain
      // and decode JSON manually in the interceptor below.
      responseType: ResponseType.plain,
    ));
    _yCommonDio.interceptors.add(CookieManager(cookieJar));
    _yCommonDio.interceptors.add(_JsonDecodeInterceptor());

    _uCommonDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _userAgent,
        'Referer': '${ApiConstants.qqMusicMainBaseUrl}/portal/player.html',
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ));
    _uCommonDio.interceptors.add(CookieManager(cookieJar));
    _uCommonDio.interceptors.add(_JsonDecodeInterceptor());

    // Login Dio: ephemeral session for QR code login flow
    _loginCookieJar = CookieJar();
    _loginDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _userAgent,
      },
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
    ));
    _loginDio.interceptors.add(CookieManager(_loginCookieJar));
  }

  /// Update login state from cookies.
  void updateLoginUin(String uin) {
    _loginUin = uin;
  }

  /// Update gtk from p_skey cookie.
  void updateGtk(String pSkey) {
    _gtk = getGtk(pSkey);
  }

  /// Traditional interface request via c.y.qq.com.
  Future<Response> yCommonRequest(
    String path,
    Map<String, dynamic> params,
  ) async {
    final queryParams = <String, dynamic>{
      ..._commonParams,
      ...params,
      'format': 'json',
    };

    try {
      final res = await _yCommonDio.get(
        path,
        queryParameters: queryParams,
      );
      return res;
    } on DioException catch (e) {
      log('QqMusic yCommonRequest failed: $path, $e');
      rethrow;
    }
  }

  /// Unified interface request via u.y.qq.com.
  ///
  /// [modules] is a map of module request bodies, e.g.:
  /// ```
  /// {
  ///   'songinfo': {
  ///     'module': 'music.pf_song_detail_svr',
  ///     'method': 'get_song_detail_yqq',
  ///     'param': { ... }
  ///   }
  /// }
  /// ```
  Future<Response> uCommonRequest(Map<String, dynamic> modules) async {
    final body = <String, dynamic>{
      'comm': {
        'uin': _loginUin,
        'format': 'json',
        'ct': 24,
        'cv': 0,
      },
      ...modules,
    };

    final queryParams = <String, dynamic>{
      ..._commonParams,
      'format': 'json',
      'data': jsonEncode(body),
    };

    try {
      final res = await _uCommonDio.get(
        ApiConstants.qqMusicUBaseUrl,
        queryParameters: queryParams,
      );
      return res;
    } on DioException catch (e) {
      log('QqMusic uCommonRequest failed: $e');
      rethrow;
    }
  }

  /// Clear all stored cookies.
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
    _loginUin = '0';
    _gtk = 0;
  }
}

/// Interceptor that decodes JSON from plain-text responses.
///
/// QQ Music API often returns `text/plain` or other non-JSON Content-Types,
/// so Dio won't auto-decode. This interceptor handles the conversion, also
/// stripping any JSONP wrappers (e.g. `callback({...})`).
class _JsonDecodeInterceptor extends Interceptor {
  static final _jsonpRegex = RegExp(r'^\w+\((.+)\);?\s*$', dotAll: true);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is String) {
      var text = (response.data as String).trim();

      // Strip JSONP wrapper if present
      final match = _jsonpRegex.firstMatch(text);
      if (match != null) {
        text = match.group(1)!;
      }

      try {
        response.data = jsonDecode(text);
      } catch (_) {
        // Leave as string if not valid JSON
      }
    }
    handler.next(response);
  }
}
