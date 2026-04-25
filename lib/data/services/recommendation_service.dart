import 'dart:developer' as dev;
import 'dart:math';

import 'package:get/get.dart';

import '../models/search/search_video_model.dart';
import '../services/user_profile_service.dart';
import '../sources/music_source_registry.dart';

class RecommendationService {
  final _registry = Get.find<MusicSourceRegistry>();

  static const _excludeTitleKeywords = [
    '合集', '串烧', '盘点', '混剪',
    '游戏', '解说', '教程', '直播', '实况', '攻略', '剪辑', 'reaction',
  ];
  static const _minDurationSeconds = 90;
  static const _maxDurationSeconds = 600;

  final _sessionRecommendedIds = <String>{};

  static const _genericKeywords = [
    '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
    '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    '粤语经典', '民谣', '摇滚', '电子音乐',
  ];

  static const _suffixes = ['热门', '精选', '经典', ''];

  Future<List<SearchVideoModel>> getRecommendations({
    List<String>? recentPlayed,
  }) async {
    if (_sessionRecommendedIds.length > 100) {
      final excess = _sessionRecommendedIds.length - 50;
      _sessionRecommendedIds.removeAll(
          _sessionRecommendedIds.take(excess).toList());
    }

    final rng = Random();
    final keywords = <String>[];

    // Build keywords from user profile (top artists)
    try {
      final profileService = Get.find<UserProfileService>();
      final profile = profileService.getUserProfile();
      if (profile != null) {
        final topArtists = profile['topArtists'] as List<dynamic>?;
        if (topArtists != null && topArtists.isNotEmpty) {
          final shuffled = topArtists.toList()..shuffle(rng);
          for (final artist in shuffled.take(4)) {
            final name = artist['name'] as String? ?? '';
            if (name.isEmpty) continue;
            final suffix = _suffixes[rng.nextInt(_suffixes.length)];
            keywords.add('$name $suffix'.trim());
          }
        }
      }
    } catch (_) {}

    // Add generic keywords for variety
    final shuffledGeneric = _genericKeywords.toList()..shuffle(rng);
    keywords.addAll(shuffledGeneric.take(3));

    // Search and collect results
    final results = <SearchVideoModel>[];
    final seenIds = <String>{};
    final recentSet = recentPlayed?.toSet() ?? {};

    final sources = _registry.availableSources.toList()..shuffle(rng);
    if (sources.isEmpty) return results;

    for (final keyword in keywords) {
      if (results.length >= 8) break;

      final prevCount = results.length;
      for (final source in sources) {
        try {
          final searchResult =
              await source.searchTracks(keyword: keyword, limit: 5);
          for (final track in searchResult.tracks) {
            if (results.length >= 8) break;
            if (_sessionRecommendedIds.contains(track.uniqueId)) continue;
            if (!seenIds.add(track.uniqueId)) continue;
            if (recentSet.contains('${track.title} - ${track.author}')) continue;
            if (!_isQualityResult(track)) continue;

            results.add(track);
            _sessionRecommendedIds.add(track.uniqueId);
          }
          if (results.length > prevCount) break;
        } catch (e) {
          dev.log('Recommendation search "$keyword" on ${source.sourceId} failed: $e');
        }
      }
    }

    results.shuffle(rng);
    return results;
  }

  bool _isQualityResult(SearchVideoModel video) {
    final seconds = _parseDurationToSeconds(video.duration);
    if (seconds != null) {
      if (seconds < _minDurationSeconds || seconds > _maxDurationSeconds) {
        return false;
      }
    }
    for (final keyword in _excludeTitleKeywords) {
      if (video.title.contains(keyword)) return false;
    }
    return true;
  }

  static int? _parseDurationToSeconds(String duration) {
    final parts = duration.split(':');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]);
      final sec = int.tryParse(parts[1]);
      if (min != null && sec != null) return min * 60 + sec;
    } else if (parts.length == 3) {
      final hr = int.tryParse(parts[0]);
      final min = int.tryParse(parts[1]);
      final sec = int.tryParse(parts[2]);
      if (hr != null && min != null && sec != null) {
        return hr * 3600 + min * 60 + sec;
      }
    }
    return null;
  }
}
