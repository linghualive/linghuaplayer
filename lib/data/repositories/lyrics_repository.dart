import 'dart:developer';

import 'package:dio/dio.dart' show Response;
import 'package:get/get.dart' hide Response;

import '../../core/crypto/wbi_sign.dart';
import '../models/player/lyrics_model.dart';
import '../providers/lyrics_provider.dart';
import '../providers/search_provider.dart';
import 'netease_repository.dart';

class LyricsRepository {
  final _lyricsProvider = Get.find<LyricsProvider>();
  final _searchProvider = Get.find<SearchProvider>();
  final _neteaseRepo = Get.find<NeteaseRepository>();

  // Common separators between artist and song name in bilibili titles
  static final _separatorPattern = RegExp(r'\s*[-–—/|]\s*');

  /// Try to extract (artist, songName) from a bilibili title.
  /// Common patterns:
  ///   "Artist - Song Name"
  ///   "Artist《Song Name》"
  ///   "Song Name"
  static (String? artist, String songName) parseTitle(String rawTitle) {
    var title = rawTitle;
    // Remove HTML tags
    title = title.replaceAll(RegExp(r'<[^>]+>'), '');
    // Remove bracketed annotations: [xxx] 【xxx】
    title = title.replaceAll(RegExp(r'[\[【][^\]】]*[\]】]'), '');
    // Remove round bracket annotations: (xxx) （xxx）
    title = title.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
    // Remove common noise words
    title = title.replaceAll(
      RegExp(
        r'官方MV|Official\s*M/?V|Music\s*Video|完整版|高音质|无损|Hi-?Res|FLAC|'
        r'自制|翻唱|cover|翻奏|钢琴版|纯享版|现场版|演唱会|歌词版|'
        r'lyric(s)?(\s*video)?|audio|MV|PV|LIVE|4K|1080[Pp]',
        caseSensitive: false,
      ),
      '',
    );
    title = title.trim();

    // Try to extract from 《》or「」
    final bookMatch = RegExp(r'(.+?)\s*[《「](.+?)[》」]').firstMatch(title);
    if (bookMatch != null) {
      final artist = bookMatch.group(1)!.trim();
      final song = bookMatch.group(2)!.trim();
      if (song.isNotEmpty) {
        return (artist.isNotEmpty ? artist : null, song);
      }
    }

    // Try splitting by separator: "Artist - Song" or "Song - Artist"
    // Heuristic: if there's exactly one separator, split there
    final parts = title.split(_separatorPattern);
    if (parts.length == 2) {
      final a = parts[0].trim();
      final b = parts[1].trim();
      if (a.isNotEmpty && b.isNotEmpty) {
        // Convention: first part is usually the artist
        return (a, b);
      }
    }

    // No structure found — return the cleaned title as song name
    final cleaned = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (null, cleaned);
  }

  /// Parse duration string like "4:30" to seconds.
  static int? parseDurationToSeconds(String duration) {
    final parts = duration.split(':');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]);
      final sec = int.tryParse(parts[1]);
      if (min != null && sec != null) return min * 60 + sec;
    }
    return null;
  }

  /// Pick the best LRCLIB result, preferring synced lyrics and matching duration.
  LyricsData? _pickBestResult(List<dynamic> results, {int? durationSec}) {
    // Sort: prefer results with synced lyrics, then closest duration match
    final withSynced = results.where((r) {
      final s = r['syncedLyrics'] as String?;
      return s != null && s.isNotEmpty;
    }).toList();

    if (withSynced.isNotEmpty) {
      // If we have duration info, pick the closest match
      if (durationSec != null) {
        withSynced.sort((a, b) {
          final da = ((a['duration'] as num?)?.toInt() ?? 0) - durationSec;
          final db = ((b['duration'] as num?)?.toInt() ?? 0) - durationSec;
          return da.abs().compareTo(db.abs());
        });
      }
      final syncedLyrics = withSynced.first['syncedLyrics'] as String;
      final parsed = LyricsData.fromLrc(syncedLyrics);
      if (parsed != null) {
        log('LRCLIB: found synced lyrics (${parsed.lines.length} lines)');
        return parsed;
      }
    }

    // Fall back to plain lyrics
    for (final item in results) {
      final plain = item['plainLyrics'] as String?;
      if (plain != null && plain.isNotEmpty) {
        log('LRCLIB: found plain lyrics only');
        return LyricsData(lines: [], plainLyrics: plain);
      }
    }

    return null;
  }

  /// Try a single LRCLIB search call, return parsed result or null.
  Future<LyricsData?> _trySearch(
    Future<Response> Function() searchFn,
    String label, {
    int? durationSec,
  }) async {
    try {
      final res = await searchFn();
      if (res.data is List && (res.data as List).isNotEmpty) {
        final result = _pickBestResult(res.data as List, durationSec: durationSec);
        if (result != null) return result;
      }
      log('LRCLIB ($label): no results');
    } catch (e) {
      log('LRCLIB ($label) failed: $e');
    }
    return null;
  }

  /// Fetch lyrics with multi-strategy LRCLIB search + bilibili subtitle fallback.
  Future<LyricsData?> getLyrics(
    String title,
    String artist,
    String duration, {
    String? bvid,
  }) async {
    final (parsedArtist, songName) = parseTitle(title);
    final durationSec = parseDurationToSeconds(duration);

    log('Lyrics lookup: title="$title" → artist="$parsedArtist" song="$songName"');

    if (songName.isEmpty) return null;

    // Strategy 1: search by parsed song name + parsed artist
    if (parsedArtist != null && parsedArtist.isNotEmpty) {
      final r = await _trySearch(
        () => _lyricsProvider.searchLrclib(songName, artistName: parsedArtist),
        'artist+track',
        durationSec: durationSec,
      );
      if (r != null) return r;
    }

    // Strategy 2: search by song name only (no artist filter)
    {
      final r = await _trySearch(
        () => _lyricsProvider.searchLrclib(songName),
        'track-only',
        durationSec: durationSec,
      );
      if (r != null) return r;
    }

    // Strategy 3: general keyword search with "artist song"
    {
      final query = parsedArtist != null
          ? '$parsedArtist $songName'
          : songName;
      final r = await _trySearch(
        () => _lyricsProvider.searchLrclibByQuery(query),
        'query',
        durationSec: durationSec,
      );
      if (r != null) return r;
    }

    // Strategy 4: Bilibili subtitle fallback
    if (bvid != null && bvid.isNotEmpty) {
      try {
        final result = await _fetchBilibiliSubtitle(bvid);
        if (result != null) return result;
      } catch (e) {
        log('Bilibili subtitle fetch failed: $e');
      }
    }

    return null;
  }

  /// Fetch lyrics from NetEase Cloud Music API.
  Future<LyricsData?> getNeteaseLyrics(int songId) async {
    try {
      final lrcText = await _neteaseRepo.getLrcLyrics(songId);
      if (lrcText == null || lrcText.isEmpty) return null;

      final parsed = LyricsData.fromLrc(lrcText);
      if (parsed != null) {
        log('NetEase: found synced lyrics (${parsed.lines.length} lines)');
        return parsed;
      }

      // If LRC parsing fails, return as plain text
      log('NetEase: LRC parse failed, returning plain text');
      return LyricsData(lines: [], plainLyrics: lrcText);
    } catch (e) {
      log('NetEase lyrics fetch error: $e');
      return null;
    }
  }

  Future<LyricsData?> _fetchBilibiliSubtitle(String bvid) async {
    final pagelistRes = await _searchProvider.getPagelist(bvid);
    if (pagelistRes.data['code'] != 0) return null;

    final pages = pagelistRes.data['data'] as List<dynamic>;
    if (pages.isEmpty) return null;
    final cid = pages.first['cid'] as int;

    final params = await WbiSign.makSign({
      'bvid': bvid,
      'cid': cid,
    });

    final res = await _lyricsProvider.getSubtitleInfo(params);
    if (res.data['code'] != 0) return null;

    final subtitle = res.data['data']?['subtitle'];
    if (subtitle == null) return null;

    final subtitles = subtitle['subtitles'] as List<dynamic>? ?? [];
    if (subtitles.isEmpty) return null;

    // Prefer Chinese subtitle
    Map<String, dynamic>? chosen;
    for (final sub in subtitles) {
      final lan = sub['lan'] as String? ?? '';
      if (lan.startsWith('zh')) {
        chosen = sub as Map<String, dynamic>;
        break;
      }
    }
    chosen ??= subtitles.first as Map<String, dynamic>;

    final subtitleUrl = chosen['subtitle_url'] as String?;
    if (subtitleUrl == null || subtitleUrl.isEmpty) return null;

    log('Fetching bilibili subtitle: $subtitleUrl');
    final subtitleRes = await _lyricsProvider.fetchSubtitleJson(subtitleUrl);
    final body = subtitleRes.data['body'] as List<dynamic>?;
    if (body == null || body.isEmpty) return null;

    return LyricsData.fromBilibiliSubtitle(body);
  }
}
