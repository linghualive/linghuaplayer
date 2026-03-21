import 'dart:developer';

import 'package:get/get.dart';

import '../models/search/search_video_model.dart';
import '../repositories/deepseek_repository.dart';
import '../services/user_profile_service.dart';
import '../sources/music_source_registry.dart';

class RecommendationService {
  final _deepseekRepo = Get.find<DeepSeekRepository>();
  final _registry = Get.find<MusicSourceRegistry>();

  static const _excludeTitleKeywords = ['合集', '串烧', '盘点', '混剪'];
  static const _minDurationSeconds = 90; // 1:30
  static const _maxDurationSeconds = 600; // 10:00

  /// Session-level set of recommended song IDs to avoid cross-batch duplicates.
  final _sessionRecommendedIds = <String>{};

  /// Normalize a song title for fuzzy deduplication.
  static String _normalizeTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)'), '') // remove parentheses
        .replaceAll(RegExp(r'（.*?）'), '') // remove full-width parentheses
        .replaceAll(RegExp(r'【.*?】'), '') // remove brackets
        .replaceAll(RegExp(r'\[.*?\]'), '') // remove square brackets
        .replaceAll(RegExp(r'\s+'), '') // remove whitespace
        .toLowerCase();
  }

  /// Generate recommended songs using the new pipeline:
  /// 1. DeepSeek generates specific song titles + artists
  /// 2. Search all registered sources for matches
  /// 3. Apply quality filtering for non-music sources
  Future<List<SearchVideoModel>> getRecommendations({
    List<String> tags = const [],
    List<String>? recentPlayed,
  }) async {
    // Trim session-level dedup set to avoid exhausting all candidates
    if (_sessionRecommendedIds.length > 100) {
      final excess = _sessionRecommendedIds.length - 50;
      final toRemove = _sessionRecommendedIds.take(excess).toList();
      _sessionRecommendedIds.removeAll(toRemove);
    }

    // Get user profile summary for enhanced recommendations
    String? profileSummary;
    try {
      final profileService = Get.find<UserProfileService>();
      profileSummary = profileService.getProfileSummaryForPrompt();
    } catch (_) {}

    final List<RecommendedSong> recommendations;
    if (tags.isNotEmpty) {
      recommendations = await _deepseekRepo.generateSongRecommendations(
        tags,
        recentPlayed: recentPlayed,
        userProfile: profileSummary,
      );
    } else {
      recommendations = await _deepseekRepo.generateRandomSongRecommendations(
        recentPlayed: recentPlayed,
        userProfile: profileSummary,
      );
    }

    final List<SearchVideoModel> results = [];
    final Set<String> seenIds = {};
    final Set<String> seenNormalizedTitles = {};

    for (final rec in recommendations) {
      try {
        final song = await _resolveRecommendedSong(rec);
        if (song == null) continue;

        // Skip if already recommended in this session
        if (_sessionRecommendedIds.contains(song.uniqueId)) continue;

        // Skip if same uniqueId in current batch
        if (!seenIds.add(song.uniqueId)) continue;

        // Skip if a song with a very similar title already exists
        final normalized = _normalizeTitle(song.title);
        if (!seenNormalizedTitles.add(normalized)) continue;

        results.add(song);
        _sessionRecommendedIds.add(song.uniqueId);
      } catch (e) {
        log('Failed to resolve "${rec.title}" by ${rec.artist}: $e');
      }
    }

    return results;
  }

  /// Resolve a recommended song to a playable SearchVideoModel.
  /// Prioritizes GD Studio, then tries at most one other source, then Bilibili.
  Future<SearchVideoModel?> _resolveRecommendedSong(
      RecommendedSong rec) async {
    final keyword = '${rec.title} ${rec.artist}';

    // 1. Prioritize GD Studio source (music-specific, best results)
    final gdSource = _registry.getSource('gdstudio');
    if (gdSource != null) {
      try {
        final result =
            await gdSource.searchTracks(keyword: keyword, limit: 3);
        if (result.tracks.isNotEmpty) {
          log('Resolved "${rec.title}" via gdstudio (priority)');
          return result.tracks.first;
        }
      } catch (e) {
        log('GD Studio failed for "${rec.title}": $e');
      }
    }

    // 2. Fallback: try at most 1 other source (skip Bilibili for quality)
    final fallbackSources = _registry.availableSources
        .where((s) => s.sourceId != 'gdstudio' && s.sourceId != 'bilibili')
        .take(1);

    for (final source in fallbackSources) {
      try {
        final result = await source.searchTracks(keyword: keyword, limit: 3);
        if (result.tracks.isEmpty) continue;
        log('Resolved "${rec.title}" via ${source.sourceId} (fallback)');
        return result.tracks.first;
      } catch (e) {
        log('Source ${source.sourceId} failed for "${rec.title}": $e');
      }
    }

    // 3. Last resort: try Bilibili with quality filtering
    final biliSource = _registry.getSource('bilibili');
    if (biliSource != null) {
      try {
        final result =
            await biliSource.searchTracks(keyword: keyword, limit: 3);
        if (result.tracks.isNotEmpty) {
          final candidates = result.tracks.where(_isQualityResult).toList();
          if (candidates.isNotEmpty) {
            candidates.sort((a, b) => b.play.compareTo(a.play));
            log('Resolved "${rec.title}" via bilibili (last resort)');
            return candidates.first;
          }
        }
      } catch (e) {
        log('Bilibili failed for "${rec.title}": $e');
      }
    }

    return null;
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
