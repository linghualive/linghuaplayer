import 'dart:developer';

import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../models/search/search_video_model.dart';

class UserProfileService {
  final _storage = Get.find<StorageService>();

  static const _profileKey = 'user_listening_profile';

  Map<String, dynamic>? getUserProfile() =>
      _storage.read<Map<String, dynamic>>(_profileKey);

  void setUserProfile(Map<String, dynamic> profile) =>
      _storage.write(_profileKey, profile);

  /// Analyze play history and build a structured user listening profile.
  void buildProfile() {
    final history = _storage.getPlayHistory();
    if (history.isEmpty) return;

    final entries = history.take(200).toList();

    // Aggregate by artist
    final artistStats = <String, _ArtistStat>{};
    // Aggregate by source
    final sourceCount = <String, int>{};
    // Track top songs
    final songStats = <String, _SongStat>{};
    int totalMs = 0;

    for (final entry in entries) {
      final videoJson = entry['video'] as Map<String, dynamic>?;
      if (videoJson == null) continue;
      final video = SearchVideoModel.fromJson(videoJson);
      final listenedMs = entry['listenedMs'] as int? ?? 0;

      // Artist aggregation
      final artist = video.author.trim();
      if (artist.isNotEmpty) {
        final stat = artistStats.putIfAbsent(
            artist, () => _ArtistStat(name: artist));
        stat.playCount++;
        stat.totalMs += listenedMs;
      }

      // Source aggregation
      final sourceName = video.source.name;
      sourceCount[sourceName] = (sourceCount[sourceName] ?? 0) + 1;

      // Song aggregation
      final songKey = '${video.title}||${video.author}';
      final songStat = songStats.putIfAbsent(
          songKey,
          () => _SongStat(
                title: video.title,
                artist: video.author,
              ));
      songStat.totalMs += listenedMs;

      totalMs += listenedMs;
    }

    // Top 10 artists by total listen time
    final sortedArtists = artistStats.values.toList()
      ..sort((a, b) => b.totalMs.compareTo(a.totalMs));
    final topArtists = sortedArtists.take(10).map((a) => {
          'name': a.name,
          'playCount': a.playCount,
          'totalMinutes': (a.totalMs / 60000).round(),
        }).toList();

    // Top 20 songs by listen time
    final sortedSongs = songStats.values.toList()
      ..sort((a, b) => b.totalMs.compareTo(a.totalMs));
    final topSongs = sortedSongs.take(20).map((s) => {
          'title': s.title,
          'artist': s.artist,
          'totalMinutes': (s.totalMs / 60000).round(),
        }).toList();

    // Source distribution
    final totalEntries = entries.length;
    final sourceDistribution = <String, double>{};
    for (final entry in sourceCount.entries) {
      sourceDistribution[entry.key] =
          double.parse((entry.value / totalEntries).toStringAsFixed(2));
    }

    final profile = {
      'topArtists': topArtists,
      'topSongs': topSongs,
      'totalListenMinutes': (totalMs / 60000).round(),
      'sourceDistribution': sourceDistribution,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    setUserProfile(profile);
    log('UserProfileService: profile built — '
        '${topArtists.length} artists, ${topSongs.length} songs, '
        '${(totalMs / 60000).round()} min total');
  }

  /// Convert user profile into a natural language summary for DeepSeek prompt.
  String? getProfileSummaryForPrompt() {
    final profile = getUserProfile();
    if (profile == null) return null;

    final buf = StringBuffer();

    final topArtists = profile['topArtists'] as List<dynamic>?;
    if (topArtists != null && topArtists.isNotEmpty) {
      buf.write('用户最常听的歌手：');
      buf.write(topArtists
          .take(5)
          .map((a) => '${a['name']}(${a['totalMinutes']}分钟)')
          .join('、'));
    }

    final topSongs = profile['topSongs'] as List<dynamic>?;
    if (topSongs != null && topSongs.isNotEmpty) {
      if (buf.isNotEmpty) buf.write('；');
      buf.write('最喜欢的歌曲：');
      buf.write(topSongs.take(10).map((s) => s['title']).join('、'));
    }

    final totalMin = profile['totalListenMinutes'] as int?;
    if (totalMin != null && totalMin > 0) {
      if (buf.isNotEmpty) buf.write('；');
      final hours = (totalMin / 60).toStringAsFixed(1);
      buf.write('总听歌时长约$hours小时');
    }

    final result = buf.toString();
    return result.isEmpty ? null : result;
  }
}

class _ArtistStat {
  final String name;
  int playCount = 0;
  int totalMs = 0;

  _ArtistStat({required this.name});
}

class _SongStat {
  final String title;
  final String artist;
  int totalMs = 0;

  _SongStat({required this.title, required this.artist});
}
