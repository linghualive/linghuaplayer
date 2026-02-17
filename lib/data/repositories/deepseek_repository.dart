import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart';

import '../providers/deepseek_provider.dart';

class RecommendedSong {
  final String title;
  final String artist;

  RecommendedSong({required this.title, required this.artist});

  factory RecommendedSong.fromJson(Map<String, dynamic> json) {
    return RecommendedSong(
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
    );
  }
}

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
            '你是一个音乐搜索词生成专家。根据用户的音乐偏好标签，生成适合在B站搜索的音乐关键词。'
            '关键词应以风格、流派、情绪、场景为主，而不是具体的歌手和歌曲名。'
            '关键词要多样化，可以组合风格+情绪、风格+场景、风格+年代等维度。'
            '生成6-10个搜索关键词。'
            '只输出一个JSON数组，不要输出其他任何内容。'
            '例如: ["华语R&B慢歌","深夜日系City Pop","粤语经典情歌","独立民谣吉他","韩系R&B节奏感","90年代港乐","电子氛围轻音乐","说唱freestyle"]',
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
            '你是一个音乐搜索词生成专家。请生成适合在B站搜索的多样化音乐关键词。'
            '关键词应以风格、流派、情绪、场景为主，覆盖不同语种和风格。'
            '可以组合风格+情绪、风格+场景、风格+年代等维度，让搜索结果丰富多样。'
            '生成8-12个搜索关键词。'
            '只输出一个JSON数组，不要输出其他任何内容。'
            '例如: ["华语流行新歌","日系治愈轻音乐","欧美indie pop","深夜R&B","古风国风纯音乐","韩语慢歌","民谣弹唱","电子舞曲EDM"]',
        userPrompt: '请生成一组多样化的音乐搜索关键词$avoidPart',
        temperature: 1.0,
        maxTokens: 400,
      );
      return _parseJsonArray(_extractContent(res));
    } catch (e) {
      log('generateRandomQueries error: $e');
      rethrow;
    }
  }

  List<RecommendedSong> _parseSongJsonArray(String content) {
    final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
    if (jsonMatch == null) throw Exception('No JSON array found in response');
    final list = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
    return list
        .map((e) => RecommendedSong.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecommendedSong>> generateSongRecommendations(
    List<String> tags, {
    List<String>? recentPlayed,
    String? userProfile,
  }) async {
    try {
      final avoidPart = recentPlayed != null && recentPlayed.isNotEmpty
          ? '\n\n不要推荐以下已听过的歌曲:\n${recentPlayed.take(20).join('\n')}'
          : '';
      final profilePart = userProfile != null && userProfile.isNotEmpty
          ? '\n\n用户听歌画像：\n$userProfile'
          : '';

      final res = await _provider.chatCompletion(
        systemPrompt:
            '你是一个音乐推荐专家。根据用户的音乐偏好标签，推荐具体的歌曲。'
            '推荐知名度较高、容易找到的歌曲。'
            '重要规则：'
            '1. 每首歌只推荐原版，不要推荐同一首歌的Live版、翻唱版、伴奏版等不同版本；'
            '2. 每位歌手最多推荐2首歌，确保歌手多样性；'
            '3. 多样化覆盖不同风格和年代。'
            '生成8-12首推荐歌曲。'
            '只输出JSON数组，每项包含title和artist，不要输出其他任何内容。'
            '例如: [{"title":"晴天","artist":"周杰伦"},{"title":"海阔天空","artist":"Beyond"}]',
        userPrompt: '用户偏好标签: ${tags.join(", ")}$avoidPart$profilePart',
        temperature: 0.9,
        maxTokens: 600,
      );
      return _parseSongJsonArray(_extractContent(res));
    } catch (e) {
      log('generateSongRecommendations error: $e');
      rethrow;
    }
  }

  Future<List<RecommendedSong>> generateRandomSongRecommendations({
    List<String>? recentPlayed,
    String? userProfile,
  }) async {
    try {
      final avoidPart = recentPlayed != null && recentPlayed.isNotEmpty
          ? '\n\n不要推荐以下已听过的歌曲:\n${recentPlayed.take(20).join('\n')}'
          : '';
      final profilePart = userProfile != null && userProfile.isNotEmpty
          ? '\n\n用户听歌画像：\n$userProfile'
          : '';

      final res = await _provider.chatCompletion(
        systemPrompt:
            '你是一个音乐推荐专家。请推荐多样化的歌曲，覆盖不同语种、风格和年代。'
            '推荐知名度较高、容易找到的歌曲。'
            '重要规则：'
            '1. 每首歌只推荐原版，不要推荐同一首歌的Live版、翻唱版、伴奏版等不同版本；'
            '2. 每位歌手最多推荐2首歌，确保歌手多样性；'
            '3. 不要推荐相同或相似的歌曲。'
            '生成8-12首推荐歌曲。'
            '只输出JSON数组，每项包含title和artist，不要输出其他任何内容。'
            '例如: [{"title":"晴天","artist":"周杰伦"},{"title":"海阔天空","artist":"Beyond"}]',
        userPrompt: '请推荐一组多样化的好听歌曲$avoidPart$profilePart',
        temperature: 1.0,
        maxTokens: 600,
      );
      return _parseSongJsonArray(_extractContent(res));
    } catch (e) {
      log('generateRandomSongRecommendations error: $e');
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
