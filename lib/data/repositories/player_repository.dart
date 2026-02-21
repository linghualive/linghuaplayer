import 'dart:developer';

import 'package:get/get.dart';

import '../../core/crypto/wbi_sign.dart';
import '../models/player/audio_stream_model.dart';
import '../models/player/play_url_model.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';

class PlayerRepository {
  final _playerProvider = Get.find<PlayerProvider>();
  final _searchProvider = Get.find<SearchProvider>();

  /// Full pipeline: BV -> CID -> PlayURL -> all audio streams sorted by quality
  Future<PlayUrlModel?> _fetchPlayUrl(String bvid) async {
    // 1. Get CID from BV id
    final pagelistRes = await _searchProvider.getPagelist(bvid);
    if (pagelistRes.data['code'] != 0) return null;

    final pages = pagelistRes.data['data'] as List<dynamic>;
    if (pages.isEmpty) return null;
    final cid = pages.first['cid'] as int;

    // 2. Get play URL with WBI signing
    // qn=127 requests the highest quality tier (8K), which also unlocks
    // the best audio streams the user's account tier allows.
    final params = await WbiSign.makSign({
      'bvid': bvid,
      'cid': cid,
      'qn': 127,
      'fnval': 4048,
      'fourk': 1,
      'voice_balance': 1,
      'gaia_source': 'pre-load',
      'web_location': 1550101,
    });

    final playRes = await _playerProvider.getPlayUrl(params);
    if (playRes.data['code'] != 0) return null;

    // 3. Parse DASH audio streams (including dolby & hi-res)
    final playUrl = PlayUrlModel.fromJson(
        playRes.data['data'] as Map<String, dynamic>);

    log('Available audio qualities: ${playUrl.availableQualities}');

    return playUrl;
  }

  /// Get the best audio stream, returns all streams sorted by quality for fallback
  Future<List<AudioStreamModel>> getAudioStreams(String bvid) async {
    final playUrl = await _fetchPlayUrl(bvid);
    if (playUrl == null) return [];
    return playUrl.audioStreams;
  }

  /// Get single best audio stream (convenience)
  Future<AudioStreamModel?> getAudioStream(String bvid) async {
    final streams = await getAudioStreams(bvid);
    if (streams.isEmpty) return null;
    log('Selected: ${streams.first.qualityLabel} '
        '(codecs=${streams.first.codecs}, bandwidth=${streams.first.bandwidth})');
    return streams.first;
  }

  /// Get CID for a BV id
  Future<int?> getCid(String bvid) async {
    final res = await _searchProvider.getPagelist(bvid);
    if (res.data['code'] == 0) {
      final data = res.data['data'] as List<dynamic>;
      if (data.isNotEmpty) return data.first['cid'] as int?;
    }
    return null;
  }

  /// Get play URL model (for more control)
  Future<PlayUrlModel?> getPlayUrl(String bvid, int cid) async {
    final params = await WbiSign.makSign({
      'bvid': bvid,
      'cid': cid,
      'qn': 127,
      'fnval': 4048,
      'fourk': 1,
      'voice_balance': 1,
      'gaia_source': 'pre-load',
      'web_location': 1550101,
    });

    final res = await _playerProvider.getPlayUrl(params);
    if (res.data['code'] == 0) {
      return PlayUrlModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    return null;
  }
}
