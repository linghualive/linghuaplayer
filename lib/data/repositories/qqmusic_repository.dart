import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/http/qqmusic_http_client.dart';
import '../models/browse_models.dart';
import '../models/player/lyrics_model.dart';
import '../models/search/search_video_model.dart';
import '../providers/qqmusic_provider.dart';

/// Repository for QQ Music data operations.
///
/// Transforms raw QQ Music API responses into app-internal models.
class QqMusicRepository {
  final QqMusicProvider _provider;

  QqMusicRepository({QqMusicProvider? provider})
      : _provider = provider ?? Get.find<QqMusicProvider>();

  // ── Search ──────────────────────────────────────────

  /// Search songs and return a SearchResult.
  Future<SearchResult> searchSongs({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final page = (offset ~/ limit) + 1;
      await _debugLog('searchSongs START: keyword=$keyword, page=$page, limit=$limit');
      final res = await _provider.searchSongs(keyword, limit: limit, page: page);
      await _debugLog('searchSongs response status=${res.statusCode}, dataType=${res.data.runtimeType}');

      final data = res.data as Map<String, dynamic>;
      await _debugLog('searchSongs keys: ${data.keys.toList()}');

      final songData = data['data']?['song'] as Map<String, dynamic>?;
      if (songData == null) {
        await _debugLog('searchSongs: data.song is null, data[data]=${data["data"]}');
        return SearchResult(tracks: [], hasMore: false, totalCount: 0);
      }

      final totalNum = songData['totalnum'] as int? ?? 0;
      final list = songData['list'] as List<dynamic>? ?? [];
      await _debugLog('searchSongs: totalNum=$totalNum, listLen=${list.length}');

      final tracks = list
          .map((s) => _qqSongToSearchVideoModel(s as Map<String, dynamic>))
          .toList();

      return SearchResult(
        tracks: tracks,
        hasMore: tracks.length >= limit,
        totalCount: totalNum,
      );
    } catch (e, st) {
      await _debugLog('searchSongs ERROR: $e\n$st');
      return SearchResult(tracks: [], hasMore: false, totalCount: 0);
    }
  }

  // ── Hot Search ──────────────────────────────────────

  /// Get hot search keywords.
  Future<List<HotKeyword>> getHotkeys() async {
    try {
      final res = await _provider.getHotkeys();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0) return [];

      final hotkey = data['data']?['hotkey'] as List<dynamic>? ?? [];
      return hotkey.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        return HotKeyword(
          keyword: item['k'] as String? ?? '',
          displayName: item['k'] as String? ?? '',
          position: entry.key,
        );
      }).toList();
    } catch (e) {
      log('QqMusic getHotkeys error: $e');
      return [];
    }
  }

  // ── Search Suggestions ──────────────────────────────

  /// Get search suggestions for autocomplete.
  Future<List<String>> getSearchSuggestions(String term) async {
    try {
      final res = await _provider.getSmartbox(term);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0) return [];

      final songList = data['data']?['song']?['itemlist'] as List<dynamic>? ?? [];
      return songList
          .map((item) => (item as Map<String, dynamic>)['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      log('QqMusic getSearchSuggestions error: $e');
      return [];
    }
  }

  // ── Playback ────────────────────────────────────────

  /// Get play URL for a song.
  ///
  /// Returns the full CDN URL or null if unavailable.
  Future<String?> getPlayUrl(String songmid, {
    String quality = '128',
    String? mediaId,
  }) async {
    try {
      final res = await _provider.getMusicPlayUrl(
        songmid, quality: quality, mediaId: mediaId,
      );
      final data = res.data as Map<String, dynamic>;

      final req0 = data['req_0'] as Map<String, dynamic>?;
      if (req0 == null) return null;

      final reqData = req0['data'] as Map<String, dynamic>?;
      if (reqData == null) return null;

      final sip = reqData['sip'] as List<dynamic>?;
      final midurlinfo = reqData['midurlinfo'] as List<dynamic>?;

      if (sip == null || sip.isEmpty || midurlinfo == null || midurlinfo.isEmpty) {
        return null;
      }

      final domain = sip[0] as String;
      final purl = (midurlinfo[0] as Map<String, dynamic>)['purl'] as String? ?? '';

      if (purl.isEmpty) return null;
      if (domain.startsWith('http://ws')) return null;

      return '$domain$purl';
    } catch (e) {
      log('QqMusic getPlayUrl error: $e');
      return null;
    }
  }

  // ── Lyrics ──────────────────────────────────────────

  /// Get lyrics for a song. Returns parsed LyricsData.
  Future<LyricsData?> getLyrics(String songmid) async {
    try {
      final res = await _provider.getLyrics(songmid);
      final data = res.data as Map<String, dynamic>;

      final lyricBase64 = data['lyric'] as String?;
      if (lyricBase64 == null || lyricBase64.isEmpty) return null;

      // QQ Music returns Base64-encoded LRC
      final lrcContent = utf8.decode(base64Decode(lyricBase64));
      return LyricsData.fromLrc(lrcContent);
    } catch (e) {
      log('QqMusic getLyrics error: $e');
      return null;
    }
  }

  // ── Playlist ────────────────────────────────────────

  /// Get hot playlists (recommended).
  Future<List<PlaylistBrief>> getHotPlaylists({int limit = 30}) async {
    try {
      final res = await _provider.getPlaylistsByCategory(limit: limit);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0) return [];

      final list = data['data']?['list'] as List<dynamic>? ?? [];
      return list.map((p) {
        final m = p as Map<String, dynamic>;
        return PlaylistBrief(
          id: (m['dissid'] ?? '').toString(),
          sourceId: 'qqmusic',
          name: m['dissname'] as String? ?? '',
          coverUrl: m['imgurl'] as String? ?? '',
          playCount: m['listennum'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('QqMusic getHotPlaylists error: $e');
      return [];
    }
  }

  /// Get playlist detail with songs.
  Future<PlaylistDetail?> getPlaylistDetail(String disstid) async {
    try {
      final res = await _provider.getPlaylistDetail(disstid);
      final data = res.data as Map<String, dynamic>;

      final cdlist = data['cdlist'] as List<dynamic>?;
      if (cdlist == null || cdlist.isEmpty) return null;

      final cd = cdlist[0] as Map<String, dynamic>;
      final songlist = cd['songlist'] as List<dynamic>? ?? [];

      final tracks = songlist
          .map((s) => _qqSongToSearchVideoModel(s as Map<String, dynamic>))
          .toList();

      return PlaylistDetail(
        id: disstid,
        sourceId: 'qqmusic',
        name: cd['dissname'] as String? ?? '',
        coverUrl: cd['logo'] as String? ?? '',
        description: cd['desc'] as String? ?? '',
        playCount: cd['visitnum'] as int? ?? 0,
        trackCount: cd['songnum'] as int? ?? tracks.length,
        creatorName: cd['nick'] as String? ?? '',
        tracks: tracks,
      );
    } catch (e) {
      log('QqMusic getPlaylistDetail error: $e');
      return null;
    }
  }

  // ── Toplist ─────────────────────────────────────────

  /// Get all toplists.
  Future<List<ToplistItem>> getToplists() async {
    try {
      final res = await _provider.getTopLists();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0) return [];

      final topList = data['data']?['topList'] as List<dynamic>? ?? [];
      return topList.map((item) {
        final m = item as Map<String, dynamic>;
        final songList = m['songList'] as List<dynamic>? ?? [];
        final previews = songList.take(3).map((s) {
          final sm = s as Map<String, dynamic>;
          return '${sm['songname'] ?? ''} - ${sm['singername'] ?? ''}';
        }).toList();

        return ToplistItem(
          id: (m['id'] ?? 0).toString(),
          sourceId: 'qqmusic',
          name: m['topTitle'] as String? ?? '',
          coverUrl: m['picUrl'] as String? ?? '',
          trackPreviews: previews,
        );
      }).toList();
    } catch (e) {
      log('QqMusic getToplists error: $e');
      return [];
    }
  }

  /// Get toplist detail (ranking songs).
  Future<PlaylistDetail?> getToplistDetail(int topId) async {
    try {
      final res = await _provider.getToplistDetail(topId);
      final data = res.data as Map<String, dynamic>;

      final req1 = data['req_1'] as Map<String, dynamic>?;
      if (req1 == null || req1['code'] != 0) return null;

      final detailData = req1['data']?['data'] as Map<String, dynamic>?;
      if (detailData == null) return null;

      final songList = detailData['song'] as List<dynamic>? ?? [];
      final tracks = songList.map((s) {
        final sm = s as Map<String, dynamic>;
        final songInfo = sm['songInfo'] as Map<String, dynamic>? ?? {};
        return _qqSongToSearchVideoModel(songInfo);
      }).toList();

      return PlaylistDetail(
        id: topId.toString(),
        sourceId: 'qqmusic',
        name: detailData['title'] as String? ?? '',
        coverUrl: '',
        trackCount: detailData['totalNum'] as int? ?? tracks.length,
        tracks: tracks,
      );
    } catch (e) {
      log('QqMusic getToplistDetail error: $e');
      return null;
    }
  }

  // ── Artist ──────────────────────────────────────────

  /// Get artist detail (hot songs + info).
  Future<ArtistDetail?> getArtistDetail(String singermid) async {
    try {
      final res = await _provider.getSingerHotSongs(singermid, limit: 50);
      final data = res.data as Map<String, dynamic>;

      final singerData = data['singer']?['data'] as Map<String, dynamic>?;
      if (singerData == null) return null;

      final singerInfo = singerData['singer_info'] as Map<String, dynamic>? ?? {};
      final songList = singerData['songlist'] as List<dynamic>? ?? [];
      final totalSong = singerData['total_song'] as int? ?? 0;

      final hotSongs = songList
          .map((s) => _qqSongToSearchVideoModel(s as Map<String, dynamic>))
          .toList();

      return ArtistDetail(
        id: singermid,
        sourceId: 'qqmusic',
        name: singerInfo['name'] as String? ?? '',
        picUrl: _buildSingerPicUrl(singerInfo['mid'] as String? ?? singermid),
        musicSize: totalSong,
        hotSongs: hotSongs,
      );
    } catch (e) {
      log('QqMusic getArtistDetail error: $e');
      return null;
    }
  }

  // ── Album ───────────────────────────────────────────

  /// Get album detail.
  Future<AlbumDetail?> getAlbumDetail(String albummid) async {
    try {
      final res = await _provider.getAlbumInfo(albummid);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0 || data['data'] == null) return null;

      final album = data['data'] as Map<String, dynamic>;
      final songList = album['list'] as List<dynamic>? ?? [];

      final tracks = songList
          .map((s) => _qqSongToSearchVideoModel(s as Map<String, dynamic>))
          .toList();

      return AlbumDetail(
        id: albummid,
        sourceId: 'qqmusic',
        name: album['name'] as String? ?? '',
        picUrl: _buildAlbumCoverUrl(albummid),
        artistName: album['singername'] as String? ?? '',
        description: album['desc'] as String? ?? '',
        tracks: tracks,
      );
    } catch (e) {
      log('QqMusic getAlbumDetail error: $e');
      return null;
    }
  }

  // ── Login ────────────────────────────────────────────

  /// Step 1: Get QR code image bytes + qrsig + ptqrtoken.
  Future<QqMusicQrCodeResult?> getQrCode() async {
    try {
      final client = QqMusicHttpClient.instance;
      client.resetLoginCookies();

      final res = await _provider.getLoginQrCode();
      final imageBytes = Uint8List.fromList(res.data as List<int>);

      // Extract qrsig from cookies
      final cookies = await client.getLoginCookies(
        Uri.parse('https://ssl.ptlogin2.qq.com'),
      );
      final qrsig = cookies
          .cast<Cookie?>()
          .firstWhere((c) => c!.name == 'qrsig', orElse: () => null)
          ?.value ?? '';

      if (qrsig.isEmpty) {
        await _debugLog('getQrCode: qrsig not found in cookies');
        return null;
      }

      final ptqrtoken = QqMusicHttpClient.hash33(qrsig);
      return QqMusicQrCodeResult(
        imageBytes: imageBytes,
        qrsig: qrsig,
        ptqrtoken: ptqrtoken,
      );
    } catch (e) {
      log('QqMusic getQrCode error: $e');
      return null;
    }
  }

  /// Step 2: Poll QR scan status.
  Future<QqMusicQrPollResult> pollQrStatus(int ptqrtoken, String qrsig) async {
    try {
      final res = await _provider.pollQrLogin(
        ptqrtoken: ptqrtoken,
        qrsig: qrsig,
      );
      final body = res.data as String;

      // Response: ptuiCB('code','0','url','0','msg', 'nick');
      final match = RegExp(r"ptuiCB\((.*?)\)").firstMatch(body);
      if (match == null) {
        return QqMusicQrPollResult(status: QqMusicQrStatus.waiting);
      }

      final parts = match.group(1)!.split("','");
      final code = parts[0].replaceAll("'", '');
      final url = parts.length > 2 ? parts[2] : '';

      switch (code) {
        case '0':
          // Extract ptsigx and uin from the redirect URL
          final sigxMatch = RegExp(r'&ptsigx=(.+?)&s_url').firstMatch(url);
          final uinMatch = RegExp(r'&uin=(.+?)&service').firstMatch(url);
          final sigx = sigxMatch?.group(1) ?? '';
          final uin = uinMatch?.group(1) ?? '';
          return QqMusicQrPollResult(
            status: QqMusicQrStatus.success,
            sigx: sigx,
            uin: uin,
          );
        case '66':
          return QqMusicQrPollResult(status: QqMusicQrStatus.waiting);
        case '67':
          return QqMusicQrPollResult(status: QqMusicQrStatus.scanned);
        case '65':
        case '68':
          return QqMusicQrPollResult(status: QqMusicQrStatus.expired);
        default:
          return QqMusicQrPollResult(status: QqMusicQrStatus.waiting);
      }
    } catch (e) {
      log('QqMusic pollQrStatus error: $e');
      return QqMusicQrPollResult(status: QqMusicQrStatus.waiting);
    }
  }

  /// Steps 3-5: Complete the login flow after QR scan success.
  ///
  /// [uin] and [sigx] are extracted from the poll response URL.
  Future<QqMusicLoginResult?> completeLogin({
    required String uin,
    required String sigx,
  }) async {
    try {
      final client = QqMusicHttpClient.instance;
      final dio = client.loginDio;

      await _debugLog('completeLogin: START uin=$uin sigx=${sigx.length}chars');

      // Step 3: check_sig — exchange ptsigx for p_skey cookie.
      // The response is a 302; CookieManager captures the Set-Cookie headers
      // (including p_skey) from this response.
      final checkSigRes = await _provider.checkSig(uin: uin, sigx: sigx);
      await _debugLog(
        'completeLogin: check_sig status=${checkSigRes.statusCode} '
        'set-cookie=${checkSigRes.headers[HttpHeaders.setCookieHeader]?.length ?? 0}',
      );

      // Follow redirect chain from check_sig to collect remaining cookies
      String? nextUrl = checkSigRes.headers.value('location');
      for (int hop = 0; hop < 5 && nextUrl != null && nextUrl.isNotEmpty; hop++) {
        await _debugLog('completeLogin: follow hop $hop → $nextUrl');
        final r = await dio.get(
          nextUrl,
          options: Options(
            followRedirects: false,
            validateStatus: (s) => s != null && s < 400,
          ),
        );
        nextUrl = (r.statusCode ?? 0) >= 300 && (r.statusCode ?? 0) < 400
            ? r.headers.value('location')
            : null;
      }

      // Extract p_skey from cookies
      String pSkey = '';
      for (final domain in [
        'https://graph.qq.com',
        'https://qq.com',
        'https://ssl.ptlogin2.graph.qq.com',
        'https://y.qq.com',
      ]) {
        final cookies = await client.getLoginCookies(Uri.parse(domain));
        await _debugLog(
          'completeLogin: cookies for $domain: '
          '${cookies.map((c) => c.name).join(', ')}',
        );
        for (final c in cookies) {
          if (c.name == 'p_skey' && c.value.isNotEmpty) {
            pSkey = c.value;
            break;
          }
        }
        if (pSkey.isNotEmpty) break;
      }

      if (pSkey.isEmpty) {
        await _debugLog('completeLogin: p_skey not found in any domain');
        return null;
      }
      await _debugLog('completeLogin: got p_skey (len=${pSkey.length})');

      // Step 4: OAuth authorize (POST with form data) → 302 with code
      final oauthRes = await _provider.oauthAuthorize(pSkey: pSkey);
      final location = oauthRes.headers.value('location') ?? '';
      await _debugLog(
        'completeLogin: oauth status=${oauthRes.statusCode} '
        'location=${location.length > 50 ? '${location.substring(0, 50)}...' : location}',
      );

      String? authCode;
      if (location.isNotEmpty) {
        final codeMatch = RegExp(r'(?<=code=)(.+?)(?=&|$)').firstMatch(location);
        authCode = codeMatch?.group(1);
      }
      if (authCode == null || authCode.isEmpty) {
        // Fallback: try response body
        final bodyStr = oauthRes.data?.toString() ?? '';
        final codeMatch = RegExp(r'code=([^&"]+)').firstMatch(bodyStr);
        authCode = codeMatch?.group(1);
      }

      if (authCode == null || authCode.isEmpty) {
        await _debugLog('completeLogin: auth code not found');
        return null;
      }
      await _debugLog('completeLogin: got authCode (len=${authCode.length})');

      // Step 5: QQ Music login via internal API
      final loginRes = await _provider.qqMusicLogin(code: authCode);
      final loginData = loginRes.data;
      Map<String, dynamic> data;
      if (loginData is String) {
        data = jsonDecode(loginData) as Map<String, dynamic>;
      } else {
        data = loginData as Map<String, dynamic>;
      }
      await _debugLog('completeLogin: qqMusicLogin keys=${data.keys}');

      final reqData = data['req']?['data'] as Map<String, dynamic>?;
      if (reqData == null) {
        await _debugLog('completeLogin: req.data null, full=$data');
        return null;
      }

      final musicId = reqData['musicid']?.toString() ?? '';
      final musicKey = reqData['musickey'] as String? ?? '';
      final loginUin = reqData['uin']?.toString() ?? '';
      await _debugLog(
        'completeLogin: musicId=$musicId musicKey-len=${musicKey.length} '
        'loginUin=$loginUin',
      );

      final effectiveUin = musicId.isNotEmpty ? musicId : loginUin;
      if (effectiveUin.isEmpty) {
        await _debugLog('completeLogin: no valid uin');
        return null;
      }

      return QqMusicLoginResult(
        uin: effectiveUin,
        pSkey: musicKey.isNotEmpty ? musicKey : pSkey,
      );
    } catch (e, st) {
      await _debugLog('completeLogin error: $e\n$st');
      return null;
    }
  }

  // ── User Playlists ──────────────────────────────────

  /// Get user playlists by UIN.
  Future<List<QqMusicPlaylistBrief>> getUserPlaylists(String uin) async {
    try {
      final res = await _provider.getUserPlaylists(uin);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 0) return [];

      final disslist = data['data']?['disslist'] as List<dynamic>? ?? [];
      return disslist.map((item) {
        final m = item as Map<String, dynamic>;
        return QqMusicPlaylistBrief(
          id: (m['tid'] ?? 0).toString(),
          name: m['diss_name'] as String? ?? '',
          coverUrl: m['diss_cover'] as String? ?? '',
          songCount: m['song_cnt'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('QqMusic getUserPlaylists error: $e');
      return [];
    }
  }

  // ── Helpers ─────────────────────────────────────────

  /// Convert a QQ Music song JSON to SearchVideoModel.
  static SearchVideoModel _qqSongToSearchVideoModel(Map<String, dynamic> song) {
    final singers = song['singer'] as List<dynamic>? ?? [];
    final author = singers
        .map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .join(' / ');

    final interval = song['interval'] as int? ?? 0;
    final albummid = song['albummid'] as String? ?? '';

    return SearchVideoModel(
      id: song['songid'] as int? ?? song['id'] as int? ?? 0,
      author: author,
      title: song['songname'] as String? ?? song['name'] as String? ?? '',
      description: song['albumname'] as String? ?? '',
      pic: albummid.isNotEmpty ? _buildAlbumCoverUrl(albummid) : '',
      duration: _formatDuration(interval),
      bvid: song['songmid'] as String? ?? song['mid'] as String? ?? '',
      source: MusicSource.qqmusic,
    );
  }

  /// Format seconds into `m:ss` string.
  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Build album cover URL from albummid.
  static String _buildAlbumCoverUrl(String albummid) {
    return 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albummid.jpg';
  }

  /// Build singer avatar URL from singermid.
  static String _buildSingerPicUrl(String singermid) {
    return 'https://y.gtimg.cn/music/photo_new/T001R300x300M000$singermid.jpg';
  }

  /// Write debug log to file for inspection.
  static Future<void> _debugLog(String msg) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/qqmusic_debug.log');
      final ts = DateTime.now().toIso8601String();
      await file.writeAsString('[$ts] $msg\n', mode: FileMode.append);
    } catch (_) {}
  }
}

// ── QQ Music Login Models ──────────────────────────────

class QqMusicQrCodeResult {
  final Uint8List imageBytes;
  final String qrsig;
  final int ptqrtoken;

  QqMusicQrCodeResult({
    required this.imageBytes,
    required this.qrsig,
    required this.ptqrtoken,
  });
}

enum QqMusicQrStatus { waiting, scanned, success, expired }

class QqMusicQrPollResult {
  final QqMusicQrStatus status;
  final String? sigx;
  final String? uin;

  QqMusicQrPollResult({required this.status, this.sigx, this.uin});
}

class QqMusicLoginResult {
  final String uin;
  final String pSkey;

  QqMusicLoginResult({required this.uin, required this.pSkey});
}

class QqMusicPlaylistBrief {
  final String id;
  final String name;
  final String coverUrl;
  final int songCount;

  QqMusicPlaylistBrief({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.songCount,
  });
}
