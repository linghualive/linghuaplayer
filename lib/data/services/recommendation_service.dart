import 'dart:developer';

import 'package:get/get.dart';

import '../models/search/search_video_model.dart';
import '../repositories/deepseek_repository.dart';
import '../repositories/netease_repository.dart';
import '../repositories/search_repository.dart';

class RecommendationService {
  final _deepseekRepo = Get.find<DeepSeekRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _searchRepo = Get.find<SearchRepository>();

  static const _excludeTitleKeywords = ['合集', '串烧', '盘点', '混剪'];
  static const _minDurationSeconds = 90; // 1:30
  static const _maxDurationSeconds = 600; // 10:00

  /// Generate recommended songs using the new pipeline:
  /// 1. DeepSeek generates specific song titles + artists
  /// 2. Search NetEase first (high quality music database)
  /// 3. Fall back to Bilibili with quality filtering
  Future<List<SearchVideoModel>> getRecommendations({
    List<String> tags = const [],
    List<String>? recentPlayed,
  }) async {
    final List<RecommendedSong> recommendations;
    if (tags.isNotEmpty) {
      recommendations = await _deepseekRepo.generateSongRecommendations(
        tags,
        recentPlayed: recentPlayed,
      );
    } else {
      recommendations = await _deepseekRepo.generateRandomSongRecommendations(
        recentPlayed: recentPlayed,
      );
    }

    final List<SearchVideoModel> results = [];
    final Set<String> seenIds = {};

    for (final rec in recommendations) {
      try {
        final song = await _resolveRecommendedSong(rec);
        if (song != null && seenIds.add(song.uniqueId)) {
          results.add(song);
        }
      } catch (e) {
        log('Failed to resolve "${rec.title}" by ${rec.artist}: $e');
      }
    }

    return results;
  }

  /// Resolve a recommended song to a playable SearchVideoModel.
  /// Tries NetEase first, then falls back to Bilibili with filtering.
  Future<SearchVideoModel?> _resolveRecommendedSong(
      RecommendedSong rec) async {
    // 1. Try NetEase first
    final neteaseResult = await _neteaseRepo.searchSongs(
      keyword: '${rec.title} ${rec.artist}',
      limit: 5,
    );
    if (neteaseResult.songs.isNotEmpty) {
      log('Resolved "${rec.title}" via NetEase');
      return neteaseResult.songs.first;
    }

    // 2. Fall back to Bilibili with quality filtering
    final keyword = '${rec.title} ${rec.artist}';
    final biliResult = await _searchRepo.searchVideos(
      keyword: keyword,
      page: 1,
    );
    if (biliResult == null || biliResult.results.isEmpty) return null;

    final candidates = biliResult.results.take(5).where(_isQualityResult).toList();
    if (candidates.isEmpty) return null;

    // Pick the one with highest play count
    candidates.sort((a, b) => b.play.compareTo(a.play));
    log('Resolved "${rec.title}" via Bilibili (filtered)');
    return candidates.first;
  }

  /// Quality filter for Bilibili search results.
  bool _isQualityResult(SearchVideoModel video) {
    // Check duration (format: "m:ss" or "mm:ss")
    final seconds = _parseDurationToSeconds(video.duration);
    if (seconds != null) {
      if (seconds < _minDurationSeconds || seconds > _maxDurationSeconds) {
        return false;
      }
    }

    // Exclude compilations, mashups, etc.
    final title = video.title;
    for (final keyword in _excludeTitleKeywords) {
      if (title.contains(keyword)) return false;
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
