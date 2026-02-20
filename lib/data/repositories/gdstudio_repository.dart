import 'dart:developer';

import 'package:get/get.dart';

import '../models/browse_models.dart';
import '../models/playback_info.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../providers/gdstudio_provider.dart';

/// Repository for GD Studio Music API.
///
/// Transforms raw API responses into app-level models.
/// Default sub-source is 'netease'; can be changed via [subSource].
class GdStudioRepository {
  final GdStudioProvider _provider;

  /// The backend sub-source to use (netease, kuwo, joox, bilibili, etc.).
  String subSource;

  GdStudioRepository({
    GdStudioProvider? provider,
    this.subSource = 'netease',
  }) : _provider = provider ?? Get.find<GdStudioProvider>();

  /// Search for tracks. Returns a [SearchResult].
  ///
  /// [offset] is converted to 1-based page number internally.
  Future<SearchResult> searchSongs({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    // Convert offset-based pagination to 1-based page number
    final page = (offset ~/ limit) + 1;

    final res = await _provider.search(
      source: subSource,
      name: keyword,
      count: limit,
      pages: page,
    );

    final data = res.data;
    if (data is! List || data.isEmpty) {
      return SearchResult(tracks: [], hasMore: false, totalCount: 0);
    }

    final tracks = <SearchVideoModel>[];
    for (final item in data) {
      try {
        final id = item['id']?.toString() ?? '';
        final name = item['name'] as String? ?? '';
        final artistList = item['artist'];
        final artist = artistList is List ? artistList.join(' / ') : '$artistList';
        final album = item['album'] as String? ?? '';
        final picId = item['pic_id']?.toString() ?? '';
        final lyricId = item['lyric_id']?.toString() ?? '';
        final source = item['source'] as String? ?? subSource;

        // Get cover image URL
        String picUrl = '';
        if (picId.isNotEmpty) {
          try {
            final picRes = await _provider.getPic(
              source: source,
              id: picId,
              size: 300,
            );
            picUrl = picRes.data?['url'] as String? ?? '';
          } catch (e) {
            log('GdStudioRepository: pic fetch failed for $picId: $e');
          }
        }

        tracks.add(SearchVideoModel(
          id: int.tryParse(id) ?? id.hashCode,
          author: artist,
          title: name,
          description: album,
          pic: picUrl,
          duration: '0:00',
          // Store extra info in bvid as "source:trackId:lyricId"
          bvid: '$source:$id:$lyricId',
          source: MusicSource.gdstudio,
        ));
      } catch (e) {
        log('GdStudioRepository: parse track error: $e');
      }
    }

    return SearchResult(
      tracks: tracks,
      hasMore: tracks.length >= limit,
      totalCount: tracks.length,
    );
  }

  /// Resolve a playable URL for the given track.
  ///
  /// [br] defaults to 999 (highest quality / lossless).
  Future<PlaybackInfo?> resolvePlayback(
    SearchVideoModel track, {
    int br = 999,
  }) async {
    final parts = track.bvid.split(':');
    if (parts.length < 2) return null;

    final source = parts[0];
    final trackId = parts[1];

    // Try qualities from highest to lowest
    final qualities = [999, 320, 192, 128];
    final streams = <StreamOption>[];

    for (final quality in qualities) {
      try {
        final res = await _provider.getUrl(
          source: source,
          id: trackId,
          br: quality,
        );

        final url = res.data?['url'] as String? ?? '';
        final actualBr = res.data?['br'];
        if (url.isNotEmpty) {
          streams.add(StreamOption(
            url: url,
            qualityLabel: _qualityLabel(quality, actualBr),
            headers: const {},
          ));
          // If we got the highest quality, no need to try lower ones
          break;
        }
      } catch (e) {
        log('GdStudioRepository: quality $quality failed: $e');
      }
    }

    if (streams.isEmpty) return null;

    return PlaybackInfo(
      audioStreams: streams,
      sourceId: 'gdstudio',
    );
  }

  /// Get lyrics (LRC format) for a track.
  Future<LyricsData?> getLyrics(SearchVideoModel track) async {
    final parts = track.bvid.split(':');
    if (parts.length < 3) return null;

    final source = parts[0];
    final lyricId = parts[2];
    if (lyricId.isEmpty) return null;

    try {
      final res = await _provider.getLyric(source: source, id: lyricId);
      final lyricText = res.data?['lyric'] as String?;
      if (lyricText == null || lyricText.isEmpty) return null;

      final parsed = LyricsData.fromLrc(lyricText);
      if (parsed != null) {
        log('GdStudio: found synced lyrics (${parsed.lines.length} lines)');
        return parsed;
      }

      // Return as plain text if LRC parsing fails
      return LyricsData(lines: [], plainLyrics: lyricText);
    } catch (e) {
      log('GdStudio lyrics fetch error: $e');
      return null;
    }
  }

  static String _qualityLabel(int br, dynamic actualBr) {
    if (actualBr is int && actualBr > 0) {
      if (actualBr >= 740) return 'FLAC 无损';
      if (actualBr >= 320) return '320kbps';
      if (actualBr >= 192) return '192kbps';
      return '128kbps';
    }
    switch (br) {
      case 999:
        return '无损';
      case 740:
        return 'FLAC';
      case 320:
        return '320kbps';
      case 192:
        return '192kbps';
      case 128:
      default:
        return '128kbps';
    }
  }
}
