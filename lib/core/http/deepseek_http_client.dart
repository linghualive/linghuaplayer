import 'package:dio/dio.dart';

class DeepSeekHttpClient {
  static DeepSeekHttpClient? _instance;
  late final Dio dio;

  DeepSeekHttpClient._();

  static DeepSeekHttpClient get instance {
    _instance ??= DeepSeekHttpClient._();
    return _instance!;
  }

  void init(String apiKey) {
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.deepseek.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ));
  }

  void updateApiKey(String apiKey) {
    dio.options.headers['Authorization'] = 'Bearer $apiKey';
  }

  bool get isInitialized => _instance != null && _instance!._isReady;

  bool get _isReady {
    try {
      // ignore: unnecessary_null_comparison
      return dio != null;
    } catch (_) {
      return false;
    }
  }
}
