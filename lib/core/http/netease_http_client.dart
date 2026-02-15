import 'dart:convert';

import 'package:dio/dio.dart';

import '../crypto/netease_crypto.dart';

/// Direct HTTP client for NetEase Cloud Music API.
///
/// Uses WEAPI/EAPI encryption to call NetEase servers directly,
/// no external proxy/wrapper service needed.
class NeteaseHttpClient {
  static NeteaseHttpClient? _instance;
  late final Dio _weapiDio;
  late final Dio _eapiDio;

  static const _baseUrl = 'https://music.163.com';
  static const _eapiBaseUrl = 'https://interface.music.163.com';
  static const _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0';

  NeteaseHttpClient._();

  static NeteaseHttpClient get instance {
    _instance ??= NeteaseHttpClient._();
    return _instance!;
  }

  void init() {
    _weapiDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _userAgent,
        'Referer': 'https://music.163.com',
        'Origin': 'https://music.163.com',
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ));

    _eapiDio = Dio(BaseOptions(
      baseUrl: _eapiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': _userAgent,
        'Referer': 'https://music.163.com',
        'Origin': 'https://music.163.com',
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.plain,
    ));
  }

  /// Send a WEAPI-encrypted POST request.
  ///
  /// [apiPath] should start with `/api/`, e.g. `/api/search/get`.
  /// It will be transformed to `/weapi/...` automatically.
  Future<Response<Map<String, dynamic>>> weapiRequest(
    String apiPath,
    Map<String, dynamic> data,
  ) async {
    final weapiPath = apiPath.replaceFirst('/api/', '/weapi/');
    data['csrf_token'] = '';

    final encrypted = NeteaseCrypto.weapi(data);
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
    return Response<Map<String, dynamic>>(
      data: parsed,
      statusCode: res.statusCode,
      requestOptions: res.requestOptions,
      headers: res.headers,
    );
  }

  /// Send an EAPI-encrypted POST request.
  ///
  /// [apiPath] should start with `/api/`, e.g. `/api/song/enhance/player/url/v1`.
  /// It will be transformed to `/eapi/...` for the URL.
  Future<Response<Map<String, dynamic>>> eapiRequest(
    String apiPath,
    Map<String, dynamic> data,
  ) async {
    final eapiPath = apiPath.replaceFirst('/api/', '/eapi/');

    // EAPI requires header and e_r fields in the encrypted data
    final now = DateTime.now().millisecondsSinceEpoch;
    data['header'] = {
      'appver': '8.10.60',
      'versioncode': '140',
      'buildver': '${now ~/ 1000}',
      'resolution': '1920x1080',
      'os': 'android',
      'requestId': '${now}_${(now % 10000).toString().padLeft(4, '0')}',
      '__csrf': '',
      'MUSIC_U': '',
      'MUSIC_A': '',
      'channel': '',
      'osver': '',
      'deviceId': '',
      'mobilename': '',
    };
    data['e_r'] = false;

    final encrypted = NeteaseCrypto.eapi(apiPath, data);
    final ip = NeteaseCrypto.generateRandomCNIP();

    final res = await _eapiDio.post<String>(
      eapiPath,
      data: 'params=${Uri.encodeComponent(encrypted['params']!)}',
      options: Options(
        headers: {
          'X-Real-IP': ip,
          'X-Forwarded-For': ip,
        },
      ),
    );

    final parsed = jsonDecode(res.data!) as Map<String, dynamic>;
    return Response<Map<String, dynamic>>(
      data: parsed,
      statusCode: res.statusCode,
      requestOptions: res.requestOptions,
      headers: res.headers,
    );
  }
}
