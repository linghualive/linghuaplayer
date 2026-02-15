import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../crypto/netease_crypto.dart';

/// Direct HTTP client for NetEase Cloud Music API.
///
/// Uses WEAPI/EAPI encryption to call NetEase servers directly,
/// no external proxy/wrapper service needed.
class NeteaseHttpClient {
  static NeteaseHttpClient? _instance;
  late final Dio _weapiDio;
  late final Dio _eapiDio;
  late final PersistCookieJar cookieJar;

  static const _baseUrl = 'https://music.163.com';
  static const _eapiBaseUrl = 'https://interface.music.163.com';

  // Web browser UA for WEAPI requests
  static const _webUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0';

  // Android app UA for EAPI requests
  static const _androidUserAgent =
      'NeteaseMusic/9.1.65.240927161425(9001065);Dalvik/2.1.0 '
      '(Linux; U; Android 14; 23013RK75C Build/UKQ1.230804.001)';

  // Android OS parameters for EAPI header
  static const _androidOs = 'android';
  static const _androidAppver = '8.20.20.231215173437';
  static const _androidOsver = '14';
  static const _androidChannel = 'xiaomi';

  late final String _deviceId;

  NeteaseHttpClient._();

  static NeteaseHttpClient get instance {
    _instance ??= NeteaseHttpClient._();
    return _instance!;
  }

  /// Generate a stable device ID (52-char hex string).
  String _generateDeviceId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(26, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final cookiePath = '${dir.path}/.netease_cookies/';
    cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    _deviceId = _generateDeviceId();

    _weapiDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _webUserAgent,
        'Referer': 'https://music.163.com',
        'Origin': 'https://music.163.com',
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ));
    _weapiDio.interceptors.add(CookieManager(cookieJar));

    _eapiDio = Dio(BaseOptions(
      baseUrl: _eapiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _androidUserAgent,
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ));
    _eapiDio.interceptors.add(CookieManager(cookieJar));
  }

  /// Extract `__csrf` token from cookies.
  Future<String> getCsrfToken() async {
    try {
      final cookies =
          await cookieJar.loadForRequest(Uri.parse(_baseUrl));
      final csrf = cookies.where((c) => c.name == '__csrf');
      if (csrf.isNotEmpty) return csrf.first.value;
    } catch (_) {}
    return '';
  }

  /// Extract `MUSIC_U` cookie value (checks both WEAPI and EAPI domains).
  Future<String> getMusicUCookie() async {
    try {
      // Check WEAPI domain first
      var cookies = await cookieJar.loadForRequest(Uri.parse(_baseUrl));
      var musicU = cookies.where((c) => c.name == 'MUSIC_U');
      if (musicU.isNotEmpty) return musicU.first.value;

      // Fallback: check EAPI domain
      cookies = await cookieJar.loadForRequest(Uri.parse(_eapiBaseUrl));
      musicU = cookies.where((c) => c.name == 'MUSIC_U');
      if (musicU.isNotEmpty) return musicU.first.value;
    } catch (_) {}
    return '';
  }

  /// Clear all stored cookies (for logout).
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }

  static const int _maxRetries = 2;

  /// Send a WEAPI-encrypted POST request with automatic retry.
  ///
  /// [apiPath] should start with `/api/`, e.g. `/api/search/get`.
  /// It will be transformed to `/weapi/...` automatically.
  Future<Response<Map<String, dynamic>>> weapiRequest(
    String apiPath,
    Map<String, dynamic> data,
  ) async {
    final weapiPath = apiPath.replaceFirst('/api/', '/weapi/');
    data['csrf_token'] = await getCsrfToken();

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final encrypted = NeteaseCrypto.weapi(data);
        // Use a fresh random IP for each attempt
        final ip = NeteaseCrypto.generateRandomCNIP();

        final res = await _weapiDio.post<String>(
          weapiPath,
          data: 'params=${Uri.encodeComponent(encrypted['params']!)}'
              '&encSecKey=${Uri.encodeComponent(encrypted['encSecKey']!)}',
          options: Options(
            headers: {
              'X-Real-IP': ip,
              'X-Forwarded-For': ip,
            },
          ),
        );

        final parsed = jsonDecode(res.data!) as Map<String, dynamic>;
        final code = parsed['code'];

        // Retry on risk control codes
        if ((code == 405 || code == 301 || code == -462) &&
            attempt < _maxRetries) {
          log('NetEase WEAPI risk control (code=$code), retrying...');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }

        return Response<Map<String, dynamic>>(
          data: parsed,
          statusCode: res.statusCode,
          requestOptions: res.requestOptions,
          headers: res.headers,
        );
      } on DioException catch (e) {
        if (attempt >= _maxRetries) rethrow;
        log('NetEase WEAPI request failed (attempt $attempt): $e');
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    // Should not reach here, but satisfy the compiler
    throw Exception('NetEase WEAPI request failed after $_maxRetries retries');
  }

  /// Build the EAPI header map matching the api-enhanced reference implementation.
  Future<Map<String, dynamic>> _buildEapiHeader() async {
    final csrf = await getCsrfToken();
    final musicU = await getMusicUCookie();
    final now = DateTime.now().millisecondsSinceEpoch;

    final header = <String, dynamic>{
      'osver': _androidOsver,
      'deviceId': _deviceId,
      'os': _androidOs,
      'appver': _androidAppver,
      'versioncode': '140',
      'mobilename': '',
      'buildver': '${now ~/ 1000}',
      'resolution': '1920x1080',
      '__csrf': csrf,
      'channel': _androidChannel,
      'requestId': '${now}_${(now % 10000).toString().padLeft(4, '0')}',
    };

    if (musicU.isNotEmpty) header['MUSIC_U'] = musicU;

    return header;
  }

  /// Build cookie string from EAPI header fields (matching api-enhanced behavior).
  String _buildEapiCookieString(Map<String, dynamic> header) {
    return header.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('; ');
  }

  /// Send an EAPI-encrypted POST request with automatic retry.
  ///
  /// [apiPath] should start with `/api/`, e.g. `/api/song/enhance/player/url/v1`.
  /// It will be transformed to `/eapi/...` for the URL.
  Future<Response<Map<String, dynamic>>> eapiRequest(
    String apiPath,
    Map<String, dynamic> data,
  ) async {
    final eapiPath = apiPath.replaceFirst('/api/', '/eapi/');

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        // Rebuild header each attempt for fresh requestId/timestamp
        final header = await _buildEapiHeader();

        // EAPI requires header and e_r fields in the encrypted data
        final reqData = Map<String, dynamic>.from(data);
        reqData['header'] = header;
        reqData['e_r'] = false;

        final encrypted = NeteaseCrypto.eapi(apiPath, reqData);
        final ip = NeteaseCrypto.generateRandomCNIP();

        final res = await _eapiDio.post<String>(
          eapiPath,
          data: 'params=${Uri.encodeComponent(encrypted['params']!)}',
          options: Options(
            headers: {
              'Cookie': _buildEapiCookieString(header),
              'X-Real-IP': ip,
              'X-Forwarded-For': ip,
            },
          ),
        );

        final parsed = jsonDecode(res.data!) as Map<String, dynamic>;
        final code = parsed['code'];

        // Retry on risk control codes
        if ((code == 405 || code == 301 || code == -462) &&
            attempt < _maxRetries) {
          log('NetEase EAPI risk control (code=$code), retrying...');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }

        return Response<Map<String, dynamic>>(
          data: parsed,
          statusCode: res.statusCode,
          requestOptions: res.requestOptions,
          headers: res.headers,
        );
      } on DioException catch (e) {
        if (attempt >= _maxRetries) rethrow;
        log('NetEase EAPI request failed (attempt $attempt): $e');
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw Exception('NetEase EAPI request failed after $_maxRetries retries');
  }

  /// Sync auth cookies (MUSIC_U etc.) from interface.music.163.com to music.163.com.
  ///
  /// After QR login via EAPI, auth cookies are stored for the EAPI domain.
  /// This ensures they're also available for WEAPI requests.
  Future<void> syncCookiesToWeapiDomain() async {
    try {
      final eapiUri = Uri.parse(_eapiBaseUrl);
      final weapiUri = Uri.parse(_baseUrl);

      final eapiCookies = await cookieJar.loadForRequest(eapiUri);
      final weapiCookies = await cookieJar.loadForRequest(weapiUri);

      final weapiCookieNames =
          weapiCookies.map((c) => c.name).toSet();

      final cookiesToSync = <Cookie>[];
      for (final cookie in eapiCookies) {
        // Sync auth-related cookies
        if (cookie.name == 'MUSIC_U' ||
            cookie.name == 'MUSIC_A' ||
            cookie.name == '__csrf' ||
            cookie.name == '__remember_me') {
          if (!weapiCookieNames.contains(cookie.name)) {
            final newCookie = Cookie(cookie.name, cookie.value)
              ..domain = '.music.163.com'
              ..path = '/';
            cookiesToSync.add(newCookie);
            log('NetEase: syncing cookie ${cookie.name} to WEAPI domain');
          }
        }
      }

      if (cookiesToSync.isNotEmpty) {
        await cookieJar.saveFromResponse(weapiUri, cookiesToSync);
        log('NetEase: synced ${cookiesToSync.length} cookies to WEAPI domain');
      }
    } catch (e) {
      log('NetEase: cookie sync error: $e');
    }
  }

  /// Debug: log all stored cookies for both domains.
  Future<void> debugPrintCookies() async {
    try {
      final eapiCookies =
          await cookieJar.loadForRequest(Uri.parse(_eapiBaseUrl));
      final weapiCookies =
          await cookieJar.loadForRequest(Uri.parse(_baseUrl));

      log('NetEase cookies for ${'_eapiBaseUrl'}:');
      for (final c in eapiCookies) {
        log('  ${c.name}=${c.value.length > 20 ? '${c.value.substring(0, 20)}...' : c.value}');
      }
      log('NetEase cookies for ${'_baseUrl'}:');
      for (final c in weapiCookies) {
        log('  ${c.name}=${c.value.length > 20 ? '${c.value.substring(0, 20)}...' : c.value}');
      }
    } catch (e) {
      log('NetEase: debugPrintCookies error: $e');
    }
  }
}
