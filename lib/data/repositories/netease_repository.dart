import 'dart:developer';

import 'package:get/get.dart';

import '../../core/http/netease_http_client.dart';
import '../models/login/netease_qrcode_model.dart';
import '../models/login/netease_user_info_model.dart';
import '../models/search/hot_search_model.dart';
import '../models/netease/netease_models.dart';
import '../models/search/search_video_model.dart';
import '../providers/netease_provider.dart';

export '../models/netease/netease_models.dart';

class NeteaseRepository {
  final _provider = Get.find<NeteaseProvider>();

  /// Get NetEase hot search keywords
  Future<List<HotSearchModel>> getHotSearch() async {
    try {
      final res = await _provider.getHotSearchDetail();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      List<dynamic> list = [];
      if (data['data'] is Map) {
        list = (data['data'] as Map<String, dynamic>)['list'] as List<dynamic>? ?? [];
      } else if (data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else if (data['result'] is Map) {
        list = (data['result'] as Map<String, dynamic>)['hots'] as List<dynamic>? ?? [];
      }

      return list.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        final keyword = item['searchWord'] as String?
            ?? item['first'] as String?
            ?? '';
        return HotSearchModel(
          keyword: keyword,
          showName: keyword,
          icon: item['iconUrl'] as String?,
          position: entry.key,
        );
      }).toList();
    } catch (e) {
      log('NetEase hot search error: $e');
      return [];
    }
  }

  static String _formatDuration(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _joinArtists(List<dynamic>? artists) {
    if (artists == null || artists.isEmpty) return '';
    return artists.map((a) => a['name'] as String? ?? '').join(' / ');
  }

  static SearchVideoModel _songToModel(Map<String, dynamic> song) {
    final artists = song['artists'] ?? song['ar'];
    final album = song['album'] ?? song['al'];
    final dt = song['duration'] ?? song['dt'] ?? 0;

    return SearchVideoModel(
      id: song['id'] as int? ?? 0,
      author: _joinArtists(artists as List<dynamic>?),
      title: song['name'] as String? ?? '',
      description: album is Map ? (album['name'] as String? ?? '') : '',
      pic: album is Map ? (album['picUrl'] as String? ?? '') : '',
      duration: _formatDuration(dt as int),
      source: MusicSource.netease,
    );
  }

  Future<NeteaseSearchResult> searchSongs({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    final res =
        await _provider.search(keyword, type: 1, limit: limit, offset: offset);
    final data = res.data;
    log('NetEase search response code: ${data['code']}');
    if (data['code'] != 200 || data['result'] == null) {
      log('NetEase search failed: code=${data['code']}, msg=${data['msg'] ?? data['message'] ?? 'unknown'}');
      return NeteaseSearchResult(songs: [], songCount: 0);
    }

    final result = data['result'] as Map<String, dynamic>;
    final songCount = result['songCount'] as int? ?? 0;
    final songList = result['songs'] as List<dynamic>? ?? [];
    log('NetEase search: found $songCount songs, returned ${songList.length}');

    final songs = songList
        .map((s) => _songToModel(s as Map<String, dynamic>))
        .toList();

    return NeteaseSearchResult(songs: songs, songCount: songCount);
  }

  Future<String?> getSongUrl(int songId, {String level = 'standard'}) async {
    try {
      final res = await _provider.getSongUrl(songId, level: level);
      final data = res.data;
      log('NetEase getSongUrl response: code=${data['code']}, hasData=${data['data'] != null}');
      if (data['code'] != 200 || data['data'] == null) {
        log('NetEase getSongUrl failed: code=${data['code']}, msg=${data['msg'] ?? data['message'] ?? 'unknown'}');
        return null;
      }

      final list = data['data'] as List<dynamic>;
      if (list.isEmpty) {
        log('NetEase getSongUrl: empty data list');
        return null;
      }

      final item = list.first as Map<String, dynamic>;
      final url = item['url'] as String?;

      // Detect 30-second trial (non-VIP): freeTrialInfo is non-null
      final freeTrialInfo = item['freeTrialInfo'];
      if (freeTrialInfo != null) {
        log('NetEase getSongUrl: song $songId is a trial (freeTrialInfo=$freeTrialInfo), rejecting');
        return null;
      }

      log('NetEase getSongUrl: url=${url != null ? '${url.substring(0, url.length > 60 ? 60 : url.length)}...' : 'null'}, code=${item['code']}, type=${item['type']}');
      return url;
    } catch (e) {
      log('NetEase getSongUrl error: $e');
      return null;
    }
  }

  Future<String?> getLrcLyrics(int songId) async {
    try {
      final res = await _provider.getLyrics(songId);
      final data = res.data;
      if (data['code'] != 200) return null;

      final lrc = data['lrc'];
      if (lrc == null) return null;
      return lrc['lyric'] as String?;
    } catch (e) {
      log('NetEase getLrcLyrics error: $e');
      return null;
    }
  }

  Future<List<SearchVideoModel>> getTopSongs({int type = 0}) async {
    try {
      final res = await _provider.getTopSong(type: type);
      final data = res.data;
      if (data['code'] != 200 || data['data'] == null) return [];

      final list = data['data'] as List<dynamic>;
      return list
          .map((s) => _songToModel(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('NetEase getTopSongs error: $e');
      return [];
    }
  }

  Future<List<NeteasePlaylistBrief>> getPersonalized({int limit = 6}) async {
    try {
      final res = await _provider.getPersonalized(limit: limit);
      final data = res.data;
      if (data['code'] != 200 || data['result'] == null) return [];

      final list = data['result'] as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['picUrl'] as String? ?? '',
          playCount: m['playCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getPersonalized error: $e');
      return [];
    }
  }

  // ── Auth Methods ──────────────────────────────────────

  Future<String?> getQrKey() async {
    try {
      final res = await _provider.getQrKey();
      final data = res.data;
      log('NetEase getQrKey response: $data');
      if (data['code'] != 200) {
        log('NetEase getQrKey failed: code=${data['code']}');
        return null;
      }
      // unikey may be at top level or nested in data
      final unikey = data['unikey'] as String? ??
          (data['data'] is Map ? data['data']['unikey'] as String? : null);
      log('NetEase getQrKey: unikey=$unikey');
      return unikey;
    } catch (e) {
      log('NetEase getQrKey error: $e');
      return null;
    }
  }

  String buildQrUrl(String unikey) {
    return 'https://music.163.com/login?codekey=$unikey';
  }

  Future<NeteaseQrcodePollResult> pollQrLogin(String key) async {
    try {
      final res = await _provider.pollQrLogin(key);
      final data = res.data as Map<String, dynamic>;
      log('NetEase pollQrLogin raw response: code=${data['code']}, keys=${data.keys.toList()}');
      final result = NeteaseQrcodePollResult.fromJson(data);

      // On success, sync cookies from EAPI domain to WEAPI domain
      if (result.isSuccess) {
        log('NetEase QR login success, syncing cookies...');
        await NeteaseHttpClient.instance.syncCookiesToWeapiDomain();
        await NeteaseHttpClient.instance.debugPrintCookies();
      }

      return result;
    } catch (e) {
      log('NetEase pollQrLogin error: $e');
      return NeteaseQrcodePollResult(code: -1, message: e.toString());
    }
  }

  Future<NeteaseUserInfoModel?> getAccountInfo() async {
    try {
      log('NetEase getAccountInfo: fetching...');
      await NeteaseHttpClient.instance.debugPrintCookies();

      final res = await _provider.getAccountInfo();
      final data = res.data as Map<String, dynamic>;
      log('NetEase getAccountInfo response: code=${data['code']}, keys=${data.keys.toList()}');

      if (data['code'] != 200) {
        log('NetEase getAccountInfo: bad code ${data['code']}');
        return null;
      }

      // The response can have profile at top level or nested in account/profile
      if (data['profile'] != null) {
        return NeteaseUserInfoModel.fromAccountResponse(data);
      }

      // Try nested structure: { account: {...}, profile: {...} }
      if (data['account'] != null) {
        final account = data['account'] as Map<String, dynamic>;
        log('NetEase getAccountInfo: found account, id=${account['id']}');
        // Profile might be at top level alongside account
        if (data['profile'] != null) {
          return NeteaseUserInfoModel.fromAccountResponse(data);
        }
        // Construct minimal info from account
        return NeteaseUserInfoModel(
          userId: account['id'] as int? ?? 0,
          nickname: account['userName'] as String? ?? '',
          avatarUrl: '',
          vipType: account['vipType'] as int? ?? 0,
        );
      }

      log('NetEase getAccountInfo: no profile or account found in response');
      return null;
    } catch (e) {
      log('NetEase getAccountInfo error: $e');
      return null;
    }
  }

  // ── Personalized Recommendations ──────────────────────

  Future<List<SearchVideoModel>> getDailyRecommendSongs() async {
    try {
      final res = await _provider.getDailyRecommendSongs();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final dailySongs = data['data']?['dailySongs'] as List<dynamic>? ?? [];
      return dailySongs
          .map((s) => _songToModel(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('NetEase getDailyRecommendSongs error: $e');
      return [];
    }
  }

  Future<List<NeteasePlaylistBrief>> getDailyRecommendPlaylists() async {
    try {
      final res = await _provider.getDailyRecommendPlaylists();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final recommend = data['recommend'] as List<dynamic>? ?? [];
      return recommend.map((item) {
        final m = item as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['picUrl'] as String? ?? '',
          playCount: m['playcount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getDailyRecommendPlaylists error: $e');
      return [];
    }
  }

  // ── Playlist Methods ──────────────────────────────────

  Future<List<NeteasePlaylistBrief>> getUserPlaylists(int uid) async {
    try {
      final res = await _provider.getUserPlaylists(uid);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final playlist = data['playlist'] as List<dynamic>? ?? [];
      return playlist.map((item) {
        final m = item as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['coverImgUrl'] as String? ?? '',
          playCount: m['playCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getUserPlaylists error: $e');
      return [];
    }
  }

  Future<NeteasePlaylistDetail?> getPlaylistDetail(int id) async {
    try {
      final res = await _provider.getPlaylistDetail(id);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200 || data['playlist'] == null) return null;

      final pl = data['playlist'] as Map<String, dynamic>;
      final tracks = (pl['tracks'] as List<dynamic>? ?? [])
          .map((s) => _songToModel(s as Map<String, dynamic>))
          .toList();

      final creator = pl['creator'] as Map<String, dynamic>? ?? {};

      return NeteasePlaylistDetail(
        id: pl['id'] as int? ?? 0,
        name: pl['name'] as String? ?? '',
        coverUrl: pl['coverImgUrl'] as String? ?? '',
        description: pl['description'] as String? ?? '',
        playCount: pl['playCount'] as int? ?? 0,
        trackCount: pl['trackCount'] as int? ?? 0,
        creatorName: creator['nickname'] as String? ?? '',
        tracks: tracks,
      );
    } catch (e) {
      log('NetEase getPlaylistDetail error: $e');
      return null;
    }
  }

  // ── Multi-type Search ─────────────────────────────────

  Future<NeteaseAlbumSearchResult> searchAlbums({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _provider.search(keyword,
          type: 10, limit: limit, offset: offset);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200 || data['result'] == null) {
        return NeteaseAlbumSearchResult(albums: [], albumCount: 0);
      }
      final result = data['result'] as Map<String, dynamic>;
      final albumCount = result['albumCount'] as int? ?? 0;
      final albumList = result['albums'] as List<dynamic>? ?? [];
      final albums = albumList.map((a) {
        final m = a as Map<String, dynamic>;
        final artist = m['artist'] as Map<String, dynamic>?;
        return NeteaseAlbumBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          picUrl: m['picUrl'] as String? ?? '',
          artistName: artist?['name'] as String? ?? '',
          publishTime: m['publishTime'] as int? ?? 0,
          size: m['size'] as int? ?? 0,
        );
      }).toList();
      return NeteaseAlbumSearchResult(albums: albums, albumCount: albumCount);
    } catch (e) {
      log('NetEase searchAlbums error: $e');
      return NeteaseAlbumSearchResult(albums: [], albumCount: 0);
    }
  }

  Future<NeteaseArtistSearchResult> searchArtists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _provider.search(keyword,
          type: 100, limit: limit, offset: offset);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200 || data['result'] == null) {
        return NeteaseArtistSearchResult(artists: [], artistCount: 0);
      }
      final result = data['result'] as Map<String, dynamic>;
      final artistCount = result['artistCount'] as int? ?? 0;
      final artistList = result['artists'] as List<dynamic>? ?? [];
      final artists = artistList.map((a) {
        final m = a as Map<String, dynamic>;
        return NeteaseArtistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          picUrl: m['picUrl'] as String? ?? m['img1v1Url'] as String? ?? '',
          musicSize: m['musicSize'] as int? ?? 0,
          albumSize: m['albumSize'] as int? ?? 0,
        );
      }).toList();
      return NeteaseArtistSearchResult(
          artists: artists, artistCount: artistCount);
    } catch (e) {
      log('NetEase searchArtists error: $e');
      return NeteaseArtistSearchResult(artists: [], artistCount: 0);
    }
  }

  Future<NeteasePlaylistSearchResult> searchPlaylists({
    required String keyword,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _provider.search(keyword,
          type: 1000, limit: limit, offset: offset);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200 || data['result'] == null) {
        return NeteasePlaylistSearchResult(playlists: [], playlistCount: 0);
      }
      final result = data['result'] as Map<String, dynamic>;
      final playlistCount = result['playlistCount'] as int? ?? 0;
      final playlistList = result['playlists'] as List<dynamic>? ?? [];
      final playlists = playlistList.map((p) {
        final m = p as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['coverImgUrl'] as String? ?? '',
          playCount: m['playCount'] as int? ?? 0,
        );
      }).toList();
      return NeteasePlaylistSearchResult(
          playlists: playlists, playlistCount: playlistCount);
    } catch (e) {
      log('NetEase searchPlaylists error: $e');
      return NeteasePlaylistSearchResult(playlists: [], playlistCount: 0);
    }
  }

  // ── Artist Detail ─────────────────────────────────────

  Future<NeteaseArtistDetail?> getArtistDetail(int id) async {
    try {
      final res = await _provider.getArtistDetail(id);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return null;

      final artist = data['artist'] as Map<String, dynamic>? ?? {};
      final hotSongList = data['hotSongs'] as List<dynamic>? ?? [];
      final hotSongs = hotSongList
          .map((s) => _songToModel(s as Map<String, dynamic>))
          .toList();

      return NeteaseArtistDetail(
        id: artist['id'] as int? ?? id,
        name: artist['name'] as String? ?? '',
        picUrl: artist['picUrl'] as String? ?? '',
        briefDesc: artist['briefDesc'] as String? ?? '',
        musicSize: artist['musicSize'] as int? ?? 0,
        albumSize: artist['albumSize'] as int? ?? 0,
        hotSongs: hotSongs,
      );
    } catch (e) {
      log('NetEase getArtistDetail error: $e');
      return null;
    }
  }

  Future<List<NeteaseAlbumBrief>> getArtistAlbums(int id,
      {int limit = 30, int offset = 0}) async {
    try {
      final res =
          await _provider.getArtistAlbums(id, limit: limit, offset: offset);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final albumList = data['hotAlbums'] as List<dynamic>? ?? [];
      return albumList.map((a) {
        final m = a as Map<String, dynamic>;
        final artist = m['artist'] as Map<String, dynamic>?;
        return NeteaseAlbumBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          picUrl: m['picUrl'] as String? ?? '',
          artistName: artist?['name'] as String? ?? '',
          publishTime: m['publishTime'] as int? ?? 0,
          size: m['size'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getArtistAlbums error: $e');
      return [];
    }
  }

  // ── Album Detail ──────────────────────────────────────

  Future<NeteaseAlbumDetail?> getAlbumDetail(int id) async {
    try {
      final res = await _provider.getAlbumDetail(id);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return null;

      final album = data['album'] as Map<String, dynamic>? ?? {};
      final songList = data['songs'] as List<dynamic>? ?? [];
      final tracks = songList
          .map((s) => _songToModel(s as Map<String, dynamic>))
          .toList();
      final artist = album['artist'] as Map<String, dynamic>?;

      return NeteaseAlbumDetail(
        id: album['id'] as int? ?? id,
        name: album['name'] as String? ?? '',
        picUrl: album['picUrl'] as String? ?? '',
        artistName: artist?['name'] as String? ?? '',
        publishTime: album['publishTime'] as int? ?? 0,
        description: album['description'] as String? ?? '',
        tracks: tracks,
      );
    } catch (e) {
      log('NetEase getAlbumDetail error: $e');
      return null;
    }
  }

  // ── Toplist ───────────────────────────────────────────

  Future<List<NeteaseToplistItem>> getToplist() async {
    try {
      final res = await _provider.getToplistDetail();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200 || data['list'] == null) return [];

      final list = data['list'] as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final tracks = m['tracks'] as List<dynamic>? ?? [];
        final previews = tracks.take(3).map((t) {
          final tm = t as Map<String, dynamic>;
          final first = tm['first'] as String? ?? '';
          final second = tm['second'] as String? ?? '';
          return '$first - $second';
        }).toList();

        return NeteaseToplistItem(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['coverImgUrl'] as String? ?? '',
          updateFrequency: m['updateFrequency'] as String? ?? '',
          trackPreviews: previews,
        );
      }).toList();
    } catch (e) {
      log('NetEase getToplist error: $e');
      return [];
    }
  }

  // ── Hot Playlists & Categories ────────────────────────

  Future<List<NeteasePlaylistBrief>> getHotPlaylistsByCategory({
    String cat = '全部',
    String order = 'hot',
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _provider.getHotPlaylists(
          cat: cat, order: order, limit: limit, offset: offset);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final playlists = data['playlists'] as List<dynamic>? ?? [];
      return playlists.map((p) {
        final m = p as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['coverImgUrl'] as String? ?? '',
          playCount: m['playCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getHotPlaylistsByCategory error: $e');
      return [];
    }
  }

  Future<List<NeteasePlaylistCategory>> getPlaylistCategories() async {
    try {
      final res = await _provider.getPlaylistCategories();
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final sub = data['sub'] as List<dynamic>? ?? [];
      return sub.map((item) {
        final m = item as Map<String, dynamic>;
        return NeteasePlaylistCategory(
          name: m['name'] as String? ?? '',
          hot: m['hot'] as bool? ?? false,
          category: m['category'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getPlaylistCategories error: $e');
      return [];
    }
  }

  Future<List<NeteasePlaylistBrief>> getHighQualityPlaylists({
    String cat = '全部',
    int limit = 30,
    int lasttime = 0,
  }) async {
    try {
      final res = await _provider.getHighQualityPlaylists(
          cat: cat, limit: limit, lasttime: lasttime);
      final data = res.data as Map<String, dynamic>;
      if (data['code'] != 200) return [];

      final playlists = data['playlists'] as List<dynamic>? ?? [];
      return playlists.map((p) {
        final m = p as Map<String, dynamic>;
        return NeteasePlaylistBrief(
          id: m['id'] as int? ?? 0,
          name: m['name'] as String? ?? '',
          coverUrl: m['coverImgUrl'] as String? ?? '',
          playCount: m['playCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      log('NetEase getHighQualityPlaylists error: $e');
      return [];
    }
  }
}
