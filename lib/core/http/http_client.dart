import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/constants/api_constants.dart';
import '../../app/constants/app_constants.dart';
import 'api_interceptor.dart';

class HttpClient {
  static HttpClient? _instance;
  late final Dio dio;
  late final PersistCookieJar cookieJar;

  HttpClient._();

  static HttpClient get instance {
    _instance ??= HttpClient._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final cookiePath = '${dir.path}/.cookies/';
    cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'user-agent': AppConstants.pcUserAgent,
        'referer': AppConstants.referer,
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.json,
      validateStatus: (status) {
        if (status == null) return false;
        return status >= 200 && status < 300 ||
            [302, 304, 307, 400, 401, 403, 404].contains(status);
      },
    ));

    dio.transformer = BackgroundTransformer();

    dio.interceptors.addAll([
      ApiInterceptor(),
      CookieManager(cookieJar),
    ]);
  }

  Future<String> getCsrf() async {
    final cookies = await cookieJar
        .loadForRequest(Uri.parse(ApiConstants.apiBaseUrl));
    final jctCookies = cookies.where((c) => c.name == 'bili_jct');
    if (jctCookies.isNotEmpty) {
      return jctCookies.first.value;
    }
    return '';
  }

  Future<void> syncCookies(List<Cookie> cookies) async {
    final domains = [
      ApiConstants.baseUrl,
      ApiConstants.apiBaseUrl,
      ApiConstants.tUrl,
    ];
    for (final domain in domains) {
      await cookieJar.saveFromResponse(Uri.parse(domain), cookies);
    }
  }

  void setAuthHeaders({
    required String mid,
    String? auroraEid,
  }) {
    dio.options.headers['x-bili-mid'] = mid;
    if (auroraEid != null) {
      dio.options.headers['x-bili-aurora-eid'] = auroraEid;
    }
    dio.options.headers['env'] = 'prod';
    dio.options.headers['app-key'] = 'android64';
    dio.options.headers['x-bili-aurora-zone'] = 'sh001';
  }

  void clearAuthHeaders() {
    dio.options.headers.remove('x-bili-mid');
    dio.options.headers.remove('x-bili-aurora-eid');
    dio.options.headers.remove('env');
    dio.options.headers.remove('app-key');
    dio.options.headers.remove('x-bili-aurora-zone');
  }
}
