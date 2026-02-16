import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart';

import '../providers/deepseek_provider.dart';

class DeepSeekRepository {
  final _provider = Get.find<DeepSeekProvider>();

  String _extractContent(dio_pkg.Response res) {
    final data = res.data as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) throw Exception('No choices in response');
    final message = choices[0]['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }

  List<String> _parseJsonArray(String content) {
    // Try to extract JSON array from the response
    final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
    if (jsonMatch == null) throw Exception('No JSON array found in response');
    final list = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  Future<List<String>> generatePreferenceTags(
      List<String> videoDescriptions) async {
    try {
      final res = await _provider.chatCompletion(
        systemPrompt:
            '你是一个音乐品味分析师。用户给你的是B站观看历史，里面混杂了各种视频（游戏、科技、生活等）。'
            '请你从中识别出与音乐相关的内容（歌曲翻唱、MV、音乐推荐、乐评等），'
            '分析出用户的音乐品味偏好，输出3-8个音乐风格/流派/情感标签。'
            '标签应该是音乐领域的，如：R&B、华语流行、说唱、民谣、电子、日系、古风、摇滚、轻音乐、爵士等。'
            '如果历史中几乎没有音乐相关内容，就根据视频类型推测用户可能喜欢的音乐风格。'
            '只输出一个JSON数组，不要输出其他任何内容。'
            '例如: ["R&B","华语流行","日系动漫","电子","民谣"]',
        userPrompt: '以下是用户的B站观看历史:\n${videoDescriptions.join('\n')}',
        temperature: 0.3,
        maxTokens: 200,
      );
      return _parseJsonArray(_extractContent(res));
    } catch (e) {
      log('generatePreferenceTags error: $e');
      rethrow;
    }
  }

  Future<List<String>> generateSearchQueries(
    List<String> tags, {
    List<String>? recentPlayed,
  }) async {
    try {
      final avoidPart = recentPlayed != null && recentPlayed.isNotEmpty
          ? '\n\n不要推荐以下已听过的歌曲:\n${recentPlayed.take(20).join('\n')}'
          : '';

      final res = await _provider.chatCompletion(
        systemPrompt:
            '你是一个音乐推荐专家。根据用户的音乐偏好标签，推荐具体的歌曲。'
            '每条推荐格式为"歌手名 歌曲名"，这样方便在B站搜索到对应的音乐视频。'
            '推荐5-10首不同歌手的经典或热门歌曲，风格要匹配用户偏好。'
            '只输出一个JSON数组，不要输出其他任何内容。'
            '例如: ["周杰伦 晴天","陈奕迅 富士山下","YOASOBI アイドル","赵雷 成都","邓紫棋 光年之外"]',
        userPrompt: '用户偏好标签: ${tags.join(", ")}$avoidPart',
        temperature: 0.9,
        maxTokens: 400,
      );
      return _parseJsonArray(_extractContent(res));
    } catch (e) {
      log('generateSearchQueries error: $e');
      rethrow;
    }
  }

  /// Generate random music search queries without any preference tags
  Future<List<String>> generateRandomQueries({
    List<String>? recentPlayed,
  }) async {
    try {
      final avoidPart = recentPlayed != null && recentPlayed.isNotEmpty
          ? '\n\n不要推荐以下已听过的歌曲:\n${recentPlayed.take(20).join('\n')}'
          : '';

      final res = await _provider.chatCompletion(
        systemPrompt:
            '你是一个音乐推荐专家。请随机推荐不同风格、不同语种的热门好听歌曲。'
            '涵盖华语、欧美、日韩等，风格多样化（流行、R&B、摇滚、民谣、电子等）。'
            '每条格式为"歌手名 歌曲名"，方便在B站搜索。'
            '推荐8-12首歌曲。'
            '只输出一个JSON数组，不要输出其他任何内容。',
        userPrompt: '请随机推荐一些好听的歌曲$avoidPart',
        temperature: 1.0,
        maxTokens: 400,
      );
      return _parseJsonArray(_extractContent(res));
    } catch (e) {
      log('generateRandomQueries error: $e');
      rethrow;
    }
  }

  Future<bool> validateApiKey(String apiKey) async {
    try {
      final dio = dio_pkg.Dio(dio_pkg.BaseOptions(
        baseUrl: 'https://api.deepseek.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ));

      final res = await dio.post(
        '/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
          'max_tokens': 1,
        },
      );

      return res.statusCode == 200;
    } on dio_pkg.DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      log('validateApiKey error: $e');
      return false;
    } catch (e) {
      log('validateApiKey error: $e');
      return false;
    }
  }
}
