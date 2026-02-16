import 'package:dio/dio.dart';

import '../../core/http/deepseek_http_client.dart';

class DeepSeekProvider {
  Dio get _dio => DeepSeekHttpClient.instance.dio;

  Future<Response> chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 500,
  }) {
    return _dio.post(
      '/chat/completions',
      data: {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );
  }
}
