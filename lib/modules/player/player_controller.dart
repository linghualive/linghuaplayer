import 'dart:developer';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../home/home_controller.dart';
import '../../data/models/music/audio_song_model.dart';
import '../../data/models/player/lyrics_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/deepseek_repository.dart';
import '../../data/repositories/lyrics_repository.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../shared/utils/app_toast.dart';

enum PlayMode { sequential, shuffle, repeatOne }

class QueueItem {
  final SearchVideoModel video;
  final String audioUrl;
  final String qualityLabel;
  final String? videoUrl;
  final String? videoQualityLabel;

  QueueItem({
    required this.video,
    required this.audioUrl,
    this.qualityLabel = '',
    this.videoUrl,
    this.videoQualityLabel,
  });
}

class PlayerController extends GetxController {
  final _playerRepo = Get.find<PlayerRepository>();
  final _searchRepo = Get.find<SearchRepository>();
  final _lyricsRepo = Get.find<LyricsRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _musicRepo = Get.find<MusicRepository>();
  final _storage = Get.find<StorageService>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // media_kit player (lazy init, only created when video mode is first used)
  mk.Player? _mediaKitPlayer;
  mkv.VideoController? _videoController;

  // Guard flag: true while opening new media to suppress spurious completed events
  bool _isSwitchingTrack = false;

  // Reactive state
  final currentVideo = Rxn<SearchVideoModel>();
  final isPlaying = false.obs;
  final isLoading = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final buffered = Duration.zero.obs;

  // Video mode state
  final isVideoMode = false.obs;
  final isFullScreen = false.obs;

  // Queue
  final queue = <QueueItem>[].obs;
  final currentIndex = (-1).obs;

  // Play mode
  final playMode = PlayMode.sequential.obs;

  // Audio quality
  final audioQualityLabel = ''.obs;
  final videoQualityLabel = ''.obs;

  // Related music
  final relatedMusic = <SearchVideoModel>[].obs;
  final relatedMusicLoading = false.obs;

  // Heart mode
  final isHeartMode = false.obs;
  final heartModeTags = <String>[].obs;
  final isHeartModeLoading = false.obs;
  bool _pendingHeartModeExit = false;
  List<QueueItem> _savedNormalQueue = [];
  int _savedNormalIndex = -1;
  SearchVideoModel? _savedCurrentVideo;

  // Lyrics
  final lyrics = Rxn<LyricsData>();
  final currentLyricsIndex = (-1).obs;
  final showLyrics = false.obs;
  final lyricsLoading = false.obs;

  AudioPlayer get audioPlayer => _audioPlayer;
  mkv.VideoController? get videoController => _videoController;

  // Auto-play guard
  bool _hasAutoPlayed = false;

  @override
  void onInit() {
    super.onInit();
    _setupAudioListeners();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    _mediaKitPlayer?.dispose();
    super.onClose();
  }

  void _setupAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (!isVideoMode.value) {
        isPlaying.value = state.playing;
      }
      if (state.processingState == ProcessingState.completed) {
        if (!isVideoMode.value) _playNext();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (!isVideoMode.value) {
        position.value = pos;
        _updateLyricsIndex(pos);
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (!isVideoMode.value && dur != null) duration.value = dur;
    });

    _audioPlayer.bufferedPositionStream.listen((buf) {
      if (!isVideoMode.value) buffered.value = buf;
    });
  }

  static final _httpHeaders = {
    'user-agent': AppConstants.pcUserAgent,
    'referer': AppConstants.referer,
  };

  Future<void> _ensureMediaKitPlayer() async {
    if (_mediaKitPlayer != null) return;

    _mediaKitPlayer = mk.Player(
      configuration: const mk.PlayerConfiguration(
        bufferSize: 5 * 1024 * 1024,
      ),
    );

    // Set HTTP headers globally on the mpv player so that all HTTP connections
    // (including audio-files loaded separately) receive the correct headers.
    // Without this, audio loaded via mpv's audio-files property won't have
    // the Referer header and may get 403 from Bilibili's CDN.
    final nativePlayer = _mediaKitPlayer!.platform as mk.NativePlayer;
    await nativePlayer.setProperty('referrer', AppConstants.referer);
    await nativePlayer.setProperty('user-agent', AppConstants.pcUserAgent);

    // Listen to media_kit player streams
    // On macOS/Linux, media_kit is used for audio too (just_audio unsupported)
    _mediaKitPlayer!.stream.playing.listen((playing) {
      if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
        isPlaying.value = playing;
      }
    });

    _mediaKitPlayer!.stream.position.listen((pos) {
      if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
        position.value = pos;
        _updateLyricsIndex(pos);
      }
    });

    _mediaKitPlayer!.stream.duration.listen((dur) {
      if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
        duration.value = dur;
      }
    });

    _mediaKitPlayer!.stream.buffer.listen((buf) {
      if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
        buffered.value = buf;
      }
    });

    _mediaKitPlayer!.stream.completed.listen((completed) {
      if (completed &&
          !_isSwitchingTrack &&
          (isVideoMode.value || Platform.isMacOS || Platform.isLinux)) {
        _playNext();
      }
    });
  }

  /// Create VideoController lazily, only when video rendering is needed.
  /// This avoids calling mpv_render_context_create during audio-only playback,
  /// which can crash on macOS due to a race condition in mpv init.
  Future<void> _ensureVideoController() async {
    await _ensureMediaKitPlayer();
    if (_videoController != null) return;

    _videoController = mkv.VideoController(
      _mediaKitPlayer!,
      configuration: const mkv.VideoControllerConfiguration(
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );
  }

  /// Navigate to player: switch to Tab 0 if on home page, otherwise push route.
  void _navigateToPlayer() {
    if (Get.currentRoute == AppRoutes.home) {
      final homeCtrl = Get.find<HomeController>();
      homeCtrl.currentIndex.value = 0;
      homeCtrl.selectedIndex.value = 0;
    } else if (Get.currentRoute != AppRoutes.player) {
      Get.toNamed(AppRoutes.player);
    }
  }

  /// Play from search result and navigate to player page
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

    // Navigate to player: switch to player tab if on home, otherwise push route
    _navigateToPlayer();

    try {
      if (video.isNetease) {
        await _playNetease(video);
      } else if (_storage.enableVideo) {
        await _playWithVideo(video);
      } else {
        await _playAudioOnly(video);
      }
    } catch (e) {
      log('Playback failed: $e');
      AppToast.error('播放失败: $e');
    }
    isLoading.value = false;
    _fetchLyrics(video);
    _loadRelatedMusic(video);
  }

  /// Auto-play a random song (called when player tab opens with empty queue).
  Future<void> playRandomIfNeeded() async {
    if (_hasAutoPlayed || currentVideo.value != null || isLoading.value) return;
    _hasAutoPlayed = true;

    const keywords = [
      '热门音乐', '流行歌曲', '经典老歌', '华语金曲',
      '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    ];
    final random = Random();
    final keyword = keywords[random.nextInt(keywords.length)];

    try {
      final result = await _searchRepo.searchVideos(keyword: keyword, page: 1);
      if (result != null && result.results.isNotEmpty) {
        final maxIndex = result.results.length.clamp(1, 5);
        final video = result.results[random.nextInt(maxIndex)];
        await playFromSearch(video);
      }
    } catch (e) {
      log('playRandomIfNeeded error: $e');
    }
  }

  Future<void> _playAudioOnly(SearchVideoModel video) async {
    // On macOS/Linux, use media_kit for audio (just_audio unsupported)
    if (Platform.isMacOS || Platform.isLinux) {
      await _playWithMediaKit(video, audioOnly: true);
      return;
    }

    // Stop media_kit if it was playing
    if (isVideoMode.value) {
      _mediaKitPlayer?.stop();
    }
    isVideoMode.value = false;

    final streams = await _playerRepo.getAudioStreams(video.bvid);
    if (streams.isEmpty) {
      AppToast.error('获取音频流失败');
      isLoading.value = false;
      return;
    }

    String? playedUrl;
    String playedQuality = '';
    for (final stream in streams) {
      log('Trying ${stream.qualityLabel} (id=${stream.id}, '
          'codecs=${stream.codecs}, bandwidth=${stream.bandwidth})');
      try {
        await _playAudioUrl(stream.baseUrl);
        playedUrl = stream.baseUrl;
        playedQuality = stream.qualityLabel;
        break;
      } catch (e) {
        log('${stream.qualityLabel} baseUrl failed: $e');
        if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
          try {
            await _playAudioUrl(stream.backupUrl!);
            playedUrl = stream.backupUrl!;
            playedQuality = stream.qualityLabel;
            break;
          } catch (e2) {
            log('${stream.qualityLabel} backupUrl failed: $e2');
          }
        }
      }
    }

    if (playedUrl == null) {
      throw Exception('All audio quality tiers failed');
    }

    log('Playing with quality: $playedQuality');
    audioQualityLabel.value = playedQuality;
    videoQualityLabel.value = '';

    _addToQueue(
      video: video,
      audioUrl: playedUrl,
      qualityLabel: playedQuality,
    );
  }

  Future<void> _playWithVideo(SearchVideoModel video) async {
    // Stop just_audio if it was playing
    if (!isVideoMode.value) {
      _audioPlayer.stop();
    }

    await _ensureVideoController();

    final playUrl = await _playerRepo.getFullPlayUrl(video.bvid);
    if (playUrl == null || playUrl.videoStreams.isEmpty) {
      // Fallback to audio-only if no video streams available
      log('No video streams available, falling back to audio-only');
      await _playAudioOnly(video);
      return;
    }

    final bestVideo = playUrl.bestVideo!;
    final bestAudio = playUrl.bestAudio;

    if (bestAudio == null) {
      throw Exception('No audio stream available');
    }

    log('Video: ${bestVideo.qualityLabel} ${bestVideo.codecs} '
        '(${bestVideo.width}x${bestVideo.height})');
    log('Audio: ${bestAudio.qualityLabel} ${bestAudio.codecs}');

    isVideoMode.value = true;
    audioQualityLabel.value = bestAudio.qualityLabel;
    videoQualityLabel.value = bestVideo.qualityLabel;

    // Use mpv's audio-files property to feed separate DASH audio
    // This is pilipala's proven approach for separate audio+video DASH streams
    final audioUrl = bestAudio.baseUrl;
    final videoUrl = bestVideo.baseUrl;

    await _openVideoWithAudio(videoUrl, audioUrl);

    _addToQueue(
      video: video,
      audioUrl: audioUrl,
      qualityLabel: bestAudio.qualityLabel,
      videoUrl: videoUrl,
      videoQualityLabel: bestVideo.qualityLabel,
    );
  }

  void _addToQueue({
    required SearchVideoModel video,
    required String audioUrl,
    String qualityLabel = '',
    String? videoUrl,
    String? videoQualityLabel,
  }) {
    final queueItem = QueueItem(
      video: video,
      audioUrl: audioUrl,
      qualityLabel: qualityLabel,
      videoUrl: videoUrl,
      videoQualityLabel: videoQualityLabel,
    );

    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      // Move to front
      final item = queue.removeAt(existingIndex);
      queue.insert(0, item);
    } else {
      queue.insert(0, queueItem);
    }
    currentIndex.value = 0;
  }

  Future<void> _playQueueItem(QueueItem item) async {
    if (item.video.isNetease) {
      if (Platform.isMacOS || Platform.isLinux) {
        await _ensureMediaKitPlayer();
      }
      isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playAudioUrlDirect(item.audioUrl);
    } else if (item.videoUrl != null && _storage.enableVideo) {
      await _ensureVideoController();
      isVideoMode.value = true;
      videoQualityLabel.value = item.videoQualityLabel ?? '';
      await _openVideoWithAudio(item.videoUrl!, item.audioUrl);
    } else {
      if (Platform.isMacOS || Platform.isLinux) {
        await _ensureMediaKitPlayer();
      }
      isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playAudioUrl(item.audioUrl);
    }
  }

  Future<void> _openVideoWithAudio(String videoUrl, String audioUrl) async {
    _isSwitchingTrack = true;
    try {
      final nativePlayer = _mediaKitPlayer!.platform as mk.NativePlayer;

      // mpv uses ':' (or ';' on Windows) as separator for multiple files in
      // audio-files. Escape them so the URL is not split incorrectly.
      final escapedAudio = Platform.isWindows
          ? audioUrl.replaceAll(';', r'\;')
          : audioUrl.replaceAll(':', r'\:');
      await nativePlayer.setProperty('audio-files', escapedAudio);

      await _mediaKitPlayer!.open(
        mk.Media(videoUrl, httpHeaders: _httpHeaders),
      );
      _isSwitchingTrack = false;
    } catch (e) {
      _isSwitchingTrack = false;
      rethrow;
    }
  }

  Future<void> _playAudioUrl(String url) async {
    // On macOS/Linux, use media_kit as just_audio doesn't support it
    if (Platform.isMacOS || Platform.isLinux) {
      await _playAudioWithMediaKit(url);
      return;
    }

    log('Playing audio URL: $url');
    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: {
            'Referer': AppConstants.referer,
            'User-Agent': AppConstants.pcUserAgent,
          },
        ),
      );
      _audioPlayer.play();
    } catch (e) {
      log('Audio source error: $e');
      rethrow;
    }
  }

  Future<void> _playNetease(SearchVideoModel video) async {
    if (isVideoMode.value) {
      _mediaKitPlayer?.stop();
    }
    isVideoMode.value = false;

    final url = await _neteaseRepo.getSongUrl(video.id);
    if (url != null && url.isNotEmpty) {
      await _playAudioUrlDirect(url);
      audioQualityLabel.value = '网易云';
      videoQualityLabel.value = '';
      _addToQueue(
        video: video,
        audioUrl: url,
        qualityLabel: '网易云',
      );
      return;
    }

    // Fallback: search on Bilibili and play the top result
    log('NetEase URL unavailable for "${video.title}", falling back to Bilibili');
    await _fallbackToBilibili(video);
  }

  /// Search for a song on Bilibili by title+author and play the top result.
  Future<void> _fallbackToBilibili(SearchVideoModel neteaseVideo) async {
    final keyword = '${neteaseVideo.title} ${neteaseVideo.author}'.trim();
    AppToast.show('网易云链接不可用，正在从B站换源播放...');

    final result = await _searchRepo.searchVideos(keyword: keyword, page: 1);
    if (result == null || result.results.isEmpty) {
      throw Exception('B站换源搜索无结果');
    }

    final fallbackVideo = result.results.first;
    log('Fallback to Bilibili: "${fallbackVideo.title}" (${fallbackVideo.bvid})');
    currentVideo.value = fallbackVideo;

    if (_storage.enableVideo) {
      await _playWithVideo(fallbackVideo);
    } else {
      await _playAudioOnly(fallbackVideo);
    }
    _fetchLyrics(fallbackVideo);
  }

  /// Search Bilibili for a fallback video matching a NetEase song.
  /// Returns the top result or null if not found.
  Future<SearchVideoModel?> _searchBilibiliFallback(
      SearchVideoModel neteaseVideo) async {
    final keyword = '${neteaseVideo.title} ${neteaseVideo.author}'.trim();
    log('Searching Bilibili fallback for: "$keyword"');
    try {
      final result =
          await _searchRepo.searchVideos(keyword: keyword, page: 1);
      if (result != null && result.results.isNotEmpty) {
        return result.results.first;
      }
    } catch (e) {
      log('Bilibili fallback search failed: $e');
    }
    return null;
  }

  Future<void> _playAudioUrlDirect(String url) async {
    // On macOS/Linux, use media_kit as just_audio doesn't support it
    if (Platform.isMacOS || Platform.isLinux) {
      await _playAudioWithMediaKit(url);
      return;
    }

    log('Playing direct audio URL: $url');
    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
      );
      _audioPlayer.play();
    } catch (e) {
      log('Direct audio source error: $e');
      rethrow;
    }
  }

  Future<void> _playWithMediaKit(SearchVideoModel video,
      {bool audioOnly = false}) async {
    await _ensureMediaKitPlayer();

    if (!audioOnly && _storage.enableVideo) {
      await _playWithVideo(video);
      return;
    }

    // Audio-only mode with media_kit (for macOS/Linux)
    final streams = await _playerRepo.getAudioStreams(video.bvid);
    if (streams.isEmpty) {
      AppToast.error('获取音频流失败');
      isLoading.value = false;
      return;
    }

    String? playedUrl;
    String playedQuality = '';

    for (final stream in streams) {
      log('Trying ${stream.qualityLabel} with media_kit');
      try {
        await _playAudioWithMediaKit(stream.baseUrl);
        playedUrl = stream.baseUrl;
        playedQuality = stream.qualityLabel;
        break;
      } catch (e) {
        log('${stream.qualityLabel} baseUrl failed: $e');
        if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
          try {
            await _playAudioWithMediaKit(stream.backupUrl!);
            playedUrl = stream.backupUrl!;
            playedQuality = stream.qualityLabel;
            break;
          } catch (e2) {
            log('${stream.qualityLabel} backupUrl failed: $e2');
          }
        }
      }
    }

    if (playedUrl == null) {
      throw Exception('All audio quality tiers failed');
    }

    log('Playing with media_kit quality: $playedQuality');
    audioQualityLabel.value = playedQuality;
    videoQualityLabel.value = '';
    isVideoMode.value = false;

    _addToQueue(
      video: video,
      audioUrl: playedUrl,
      qualityLabel: playedQuality,
    );
  }

  Future<void> _playAudioWithMediaKit(String url) async {
    log('Playing audio with media_kit: $url');
    _isSwitchingTrack = true;
    try {
      _audioPlayer.stop();
      await _ensureMediaKitPlayer();

      await _mediaKitPlayer!.open(
        mk.Media(url, httpHeaders: _httpHeaders),
      );
      _isSwitchingTrack = false;
      await _mediaKitPlayer!.play();
    } catch (e) {
      _isSwitchingTrack = false;
      log('Media kit audio playback error: $e');
      rethrow;
    }
  }

  /// Switch the current track between video and audio-only mode.
  Future<void> toggleVideoMode() async {
    if (currentIndex.value < 0 || currentIndex.value >= queue.length) return;
    final item = queue[currentIndex.value];

    if (item.video.isNetease) {
      AppToast.show('网易云音乐暂不支持视频模式');
      return;
    }
    final currentPos = position.value;

    if (isVideoMode.value) {
      // Switch to audio-only
      _mediaKitPlayer?.stop();
      isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playAudioUrl(item.audioUrl);
      if (currentPos > Duration.zero) {
        await Future.delayed(const Duration(milliseconds: 200));
        _audioPlayer.seek(currentPos);
      }
    } else {
      // Switch to video
      if (item.videoUrl != null) {
        _audioPlayer.stop();
        await _ensureVideoController();
        isVideoMode.value = true;
        videoQualityLabel.value = item.videoQualityLabel ?? '';
        await _openVideoWithAudio(item.videoUrl!, item.audioUrl);
        if (currentPos > Duration.zero) {
          await Future.delayed(const Duration(milliseconds: 500));
          _mediaKitPlayer?.seek(currentPos);
        }
      } else {
        // No video URL available, try to fetch it
        try {
          final playUrl =
              await _playerRepo.getFullPlayUrl(item.video.bvid);
          if (playUrl != null &&
              playUrl.videoStreams.isNotEmpty &&
              playUrl.bestAudio != null) {
            final bestVideo = playUrl.bestVideo!;
            final bestAudio = playUrl.bestAudio!;
            // Update queue item with video URL
            final newItem = QueueItem(
              video: item.video,
              audioUrl: bestAudio.baseUrl,
              qualityLabel: bestAudio.qualityLabel,
              videoUrl: bestVideo.baseUrl,
              videoQualityLabel: bestVideo.qualityLabel,
            );
            queue[currentIndex.value] = newItem;

            _audioPlayer.stop();
            await _ensureVideoController();
            isVideoMode.value = true;
            audioQualityLabel.value = bestAudio.qualityLabel;
            videoQualityLabel.value = bestVideo.qualityLabel;
            await _openVideoWithAudio(bestVideo.baseUrl, bestAudio.baseUrl);
            if (currentPos > Duration.zero) {
              await Future.delayed(const Duration(milliseconds: 500));
              _mediaKitPlayer?.seek(currentPos);
            }
          } else {
            AppToast.show('该视频无画面资源');
          }
        } catch (e) {
          log('Failed to fetch video: $e');
          AppToast.error('获取视频失败');
        }
      }
    }
  }

  void togglePlay() {
    if ((isVideoMode.value || Platform.isMacOS || Platform.isLinux) &&
        _mediaKitPlayer != null) {
      _mediaKitPlayer!.playOrPause();
    } else {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
    }
  }

  void seekTo(Duration pos) {
    if ((isVideoMode.value || Platform.isMacOS || Platform.isLinux) &&
        _mediaKitPlayer != null) {
      _mediaKitPlayer!.seek(pos);
    } else {
      _audioPlayer.seek(pos);
    }
  }

  void _playNext() {
    if (_pendingHeartModeExit) {
      _pendingHeartModeExit = false;
      _exitHeartModeAndRestoreQueue();
      return;
    }

    switch (playMode.value) {
      case PlayMode.repeatOne:
        seekTo(Duration.zero);
        if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
          _mediaKitPlayer?.play();
        } else {
          _audioPlayer.play();
        }
        break;
      case PlayMode.shuffle:
        if (queue.length <= 1) {
          _autoPlayNext();
          return;
        }
        // Pick a random song (not the current one at index 0)
        final rng = Random();
        final next = 1 + rng.nextInt(queue.length - 1);
        playAt(next);
        break;
      case PlayMode.sequential:
        skipNext();
        break;
    }
  }

  void _stopPlayback() {
    if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
      _mediaKitPlayer?.stop();
    } else {
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _autoPlayNext() async {
    if (isHeartMode.value) {
      await _heartModeAutoNext();
      return;
    }

    final video = currentVideo.value;
    if (video == null) return;

    // 1. 从 relatedMusic 中找不在队列中的歌曲
    final queueIds = queue.map((q) => q.video.uniqueId).toSet();
    final candidates = relatedMusic
        .where((s) => !queueIds.contains(s.uniqueId))
        .toList();

    if (candidates.isNotEmpty) {
      await playFromSearch(candidates.first);
      return;
    }

    // 2. 第二优先级：发现更多歌曲
    try {
      List<SearchVideoModel> moreSongs = [];
      if (video.isBilibili && video.mid > 0) {
        moreSongs = await _discoverBilibiliSongs(video);
      } else if (video.isNetease) {
        moreSongs = await _discoverNeteaseSongs(video);
      }

      final filtered = moreSongs
          .where((s) => !queueIds.contains(s.uniqueId))
          .toList();
      if (filtered.isNotEmpty) {
        await playFromSearch(filtered.first);
        return;
      }
    } catch (e) {
      log('Auto-play discover error: $e');
    }

    // 3. 全部耗尽，停止播放
    _stopPlayback();
  }

  Future<List<SearchVideoModel>> _discoverBilibiliSongs(
      SearchVideoModel video) async {
    final seasonsResult = await _musicRepo.getMemberSeasons(video.mid);
    for (final season in seasonsResult.seasons) {
      final page = await loadCollectionPage(season, pn: 1);
      if (page.items.isNotEmpty) return page.items;
    }
    return [];
  }

  Future<List<SearchVideoModel>> _discoverNeteaseSongs(
      SearchVideoModel video) async {
    if (video.author.isEmpty) return [];
    final result = await _neteaseRepo.searchSongs(
      keyword: video.author,
      limit: 20,
    );
    return result.songs.where((s) => s.id != video.id).toList();
  }

  // ── Heart Mode ──

  Future<void> activateHeartMode(List<String> tags) async {
    // Save current queue state
    _savedNormalQueue = List.from(queue);
    _savedNormalIndex = currentIndex.value;
    _savedCurrentVideo = currentVideo.value;

    isHeartMode.value = true;
    heartModeTags.assignAll(tags);
    isHeartModeLoading.value = true;

    try {
      final deepseekRepo = Get.find<DeepSeekRepository>();
      final List<String> queries;

      if (tags.isNotEmpty) {
        queries = await deepseekRepo.generateSearchQueries(tags);
      } else {
        queries = await deepseekRepo.generateRandomQueries();
      }

      final List<SearchVideoModel> songs = [];
      final Set<String> seenIds = {};

      for (final query in queries) {
        try {
          final result =
              await _searchRepo.searchVideos(keyword: query, page: 1);
          if (result != null && result.results.isNotEmpty) {
            final video = result.results.first;
            if (seenIds.add(video.uniqueId)) {
              songs.add(video);
            }
          }
        } catch (e) {
          log('Heart mode search for "$query" failed: $e');
        }
      }

      if (songs.isEmpty) {
        AppToast.error('未找到推荐歌曲');
        _restoreFromHeartMode();
        return;
      }

      // Clear queue and play heart mode songs
      queue.clear();
      currentIndex.value = -1;
      await playFromSearch(songs.first);

      // Add remaining songs to queue
      for (int i = 1; i < songs.length; i++) {
        await addToQueueSilent(songs[i]);
      }

      AppToast.show('心动模式已开启');
    } catch (e) {
      log('activateHeartMode error: $e');
      AppToast.error('心动模式启动失败');
      _restoreFromHeartMode();
    } finally {
      isHeartModeLoading.value = false;
    }
  }

  void deactivateHeartMode() {
    _pendingHeartModeExit = true;
    AppToast.show('当前曲目播完后将退出心动模式');
  }

  void _exitHeartModeAndRestoreQueue() {
    isHeartMode.value = false;
    heartModeTags.clear();

    queue.assignAll(_savedNormalQueue);
    currentIndex.value = 0;

    if (_savedNormalQueue.isNotEmpty) {
      // Play the first item in the restored queue
      final item = queue[0];
      currentVideo.value = item.video;
      _playQueueItem(item);
    } else {
      currentVideo.value = _savedCurrentVideo;
      _stopPlayback();
    }

    _savedNormalQueue = [];
    _savedNormalIndex = -1;
    _savedCurrentVideo = null;

    AppToast.show('已退出心动模式');
  }

  void _restoreFromHeartMode() {
    isHeartMode.value = false;
    heartModeTags.clear();
    _pendingHeartModeExit = false;

    queue.assignAll(_savedNormalQueue);
    currentIndex.value = 0;
    currentVideo.value = _savedCurrentVideo;

    _savedNormalQueue = [];
    _savedNormalIndex = -1;
    _savedCurrentVideo = null;
  }

  Future<void> _heartModeAutoNext() async {
    isHeartModeLoading.value = true;
    try {
      final deepseekRepo = Get.find<DeepSeekRepository>();

      final recentPlayed =
          queue.map((q) => '${q.video.title} - ${q.video.author}').toList();

      final List<String> queries;
      if (heartModeTags.isNotEmpty) {
        queries = await deepseekRepo.generateSearchQueries(
          heartModeTags.toList(),
          recentPlayed: recentPlayed,
        );
      } else {
        queries = await deepseekRepo.generateRandomQueries(
          recentPlayed: recentPlayed,
        );
      }

      final queueIds = queue.map((q) => q.video.uniqueId).toSet();

      for (final query in queries) {
        try {
          final result =
              await _searchRepo.searchVideos(keyword: query, page: 1);
          if (result != null && result.results.isNotEmpty) {
            final video = result.results.first;
            if (!queueIds.contains(video.uniqueId)) {
              await playFromSearch(video);
              isHeartModeLoading.value = false;
              return;
            }
          }
        } catch (e) {
          log('Heart mode auto-next search for "$query" failed: $e');
        }
      }

      // If nothing new found, stop
      _stopPlayback();
      AppToast.show('心动模式暂无更多推荐');
    } catch (e) {
      log('_heartModeAutoNext error: $e');
      _stopPlayback();
    } finally {
      isHeartModeLoading.value = false;
    }
  }

  void toggleHeartMode() {
    if (isHeartMode.value) {
      deactivateHeartMode();
    }
  }

  Future<void> skipNext() async {
    if (queue.length > 1) {
      // Remove current (index 0), play new front
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
      _loadRelatedMusic(item.video);
    } else {
      // Last song in queue, trigger recommendation
      _autoPlayNext();
    }
  }

  Future<void> skipPrevious() async {
    if (position.value.inSeconds > 3) {
      seekTo(Duration.zero);
    } else {
      // Already at front, trigger recommendation
      _autoPlayNext();
    }
  }

  void togglePlayMode() {
    switch (playMode.value) {
      case PlayMode.sequential:
        playMode.value = PlayMode.shuffle;
        break;
      case PlayMode.shuffle:
        playMode.value = PlayMode.repeatOne;
        break;
      case PlayMode.repeatOne:
        playMode.value = PlayMode.sequential;
        break;
    }
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= queue.length) return;
    // Move the selected item to front
    if (index != 0) {
      final item = queue.removeAt(index);
      queue.insert(0, item);
    }
    currentIndex.value = 0;
    final item = queue[0];
    currentVideo.value = item.video;
    audioQualityLabel.value = item.qualityLabel;
    await _playQueueItem(item);
    _fetchLyrics(item.video);
    _loadRelatedMusic(item.video);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    // currentIndex is always 0 (currently playing is always first)
  }

  void enterFullScreen() {
    isFullScreen.value = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void exitFullScreen() {
    isFullScreen.value = false;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  void removeFromQueue(int index) {
    if (index == 0) return; // Can't remove currently playing
    queue.removeAt(index);
  }

  void clearQueue() {
    if (isVideoMode.value || Platform.isMacOS || Platform.isLinux) {
      _mediaKitPlayer?.stop();
    } else {
      _audioPlayer.stop();
    }
    isVideoMode.value = false;
    queue.clear();
    currentIndex.value = -1;
    currentVideo.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    lyrics.value = null;
    currentLyricsIndex.value = -1;
    showLyrics.value = false;
    lyricsLoading.value = false;
    relatedMusic.clear();
    relatedMusicLoading.value = false;
  }

  // -- Related Music --

  void _loadRelatedMusic(SearchVideoModel video) {
    relatedMusic.clear();
    relatedMusicLoading.value = true;

    final Future<List<SearchVideoModel>> fetchFuture;
    if (video.isNetease) {
      fetchFuture = _neteaseRepo
          .searchSongs(keyword: video.title, limit: 20)
          .then((result) =>
              result.songs.where((s) => s.id != video.id).toList());
    } else {
      fetchFuture = _musicRepo.getRelatedVideos(video.bvid);
    }

    fetchFuture.then((results) {
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        relatedMusic.assignAll(results);
        relatedMusicLoading.value = false;
      }
    }).catchError((e) {
      log('Related music fetch error: $e');
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        relatedMusicLoading.value = false;
      }
    });
  }

  /// Load uploader's seasons/series (合集)
  Future<MemberSeasonsResult> loadUploaderSeasons() async {
    final video = currentVideo.value;
    if (video == null || video.isNetease || video.mid <= 0) {
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }

    try {
      return await _musicRepo.getMemberSeasons(video.mid);
    } catch (e) {
      log('Uploader seasons fetch error: $e');
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }
  }

  /// Load one page of videos in a collection (合集 or 系列)
  Future<CollectionPage> loadCollectionPage(
      MemberSeason season, {int pn = 1}) async {
    final video = currentVideo.value;
    if (video == null || video.isNetease || video.mid <= 0) {
      return CollectionPage(items: [], total: 0);
    }

    try {
      if (season.category == 0 && season.seasonId > 0) {
        return await _musicRepo.getSeasonDetail(
          mid: video.mid,
          seasonId: season.seasonId,
          pn: pn,
        );
      } else if (season.seriesId > 0) {
        return await _musicRepo.getSeriesDetail(
          mid: video.mid,
          seriesId: season.seriesId,
          pn: pn,
        );
      }
      return CollectionPage(items: [], total: 0);
    } catch (e) {
      log('Collection page fetch error: $e');
      return CollectionPage(items: [], total: 0);
    }
  }

  // -- Lyrics --

  void _fetchLyrics(SearchVideoModel video) {
    lyrics.value = null;
    currentLyricsIndex.value = -1;
    lyricsLoading.value = true;

    final fetchFuture = video.isNetease
        ? _lyricsRepo.getNeteaseLyrics(video.id)
        : _lyricsRepo.getLyrics(video.title, video.author, video.duration,
            bvid: video.bvid);

    fetchFuture.then((result) {
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        lyrics.value = result;
        lyricsLoading.value = false;
      }
    }).catchError((e) {
      log('Lyrics fetch error: $e');
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        lyricsLoading.value = false;
      }
    });
  }

  void _updateLyricsIndex(Duration pos) {
    final data = lyrics.value;
    if (data == null || !data.hasSyncedLyrics) return;

    final lines = data.lines;
    // Binary search for the last line whose timestamp <= pos
    int lo = 0, hi = lines.length - 1;
    int result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (lines[mid].timestamp <= pos) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (result != currentLyricsIndex.value) {
      currentLyricsIndex.value = result;
    }
  }

  void toggleLyricsView() {
    showLyrics.value = !showLyrics.value;
  }

  bool get hasCurrentTrack => currentVideo.value != null;

  /// Play from an AU audio song (Bilibili audio channel).
  /// Tries to get the direct audio URL from the AU API first,
  /// then falls back to the standard BV-based playback.
  Future<void> playFromAudioSong(AudioSongModel song) async {
    final video = song.toSearchVideoModel();
    isLoading.value = true;
    currentVideo.value = video;

    // Navigate to player: switch to player tab if on home, otherwise push route
    _navigateToPlayer();

    try {
      // Try AU audio URL first
      final musicRepo = Get.find<MusicRepository>();
      final audioUrl = await musicRepo.getAudioUrl(song.id);

      if (audioUrl != null && audioUrl.isNotEmpty) {
        // Stop media_kit if it was playing
        if (isVideoMode.value) {
          _mediaKitPlayer?.stop();
        }
        isVideoMode.value = false;

        await _playAudioUrl(audioUrl);
        audioQualityLabel.value = 'AU';
        videoQualityLabel.value = '';

        _addToQueue(
          video: video,
          audioUrl: audioUrl,
          qualityLabel: 'AU',
        );
      } else if (video.bvid.isNotEmpty) {
        // Fallback to standard BV-based playback
        await _playAudioOnly(video);
      } else {
        throw Exception('No playable URL');
      }
    } catch (e) {
      log('AU playback failed: $e');
      // Fallback to BV-based playback if bvid is available
      if (video.bvid.isNotEmpty) {
        try {
          await _playAudioOnly(video);
        } catch (e2) {
          AppToast.error('播放失败: $e2');
        }
      } else {
        AppToast.error('播放失败: $e');
      }
    }
    isLoading.value = false;
    _fetchLyrics(video);
    _loadRelatedMusic(video);
  }

  /// Add a video to the queue silently (no snackbar).
  /// Returns true if added successfully, false if already in queue or failed.
  Future<bool> addToQueueSilent(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) return false;

    try {
      if (video.isNetease) {
        final url = await _neteaseRepo.getSongUrl(video.id);
        if (url != null && url.isNotEmpty) {
          queue.add(QueueItem(
            video: video,
            audioUrl: url,
            qualityLabel: '网易云',
          ));
        } else {
          // Fallback to Bilibili
          final fallback = await _searchBilibiliFallback(video);
          if (fallback == null) return false;
          return await addToQueueSilent(fallback);
        }
      } else if (_storage.enableVideo) {
        final playUrl = await _playerRepo.getFullPlayUrl(video.bvid);
        if (playUrl != null &&
            playUrl.videoStreams.isNotEmpty &&
            playUrl.bestAudio != null) {
          final bestVideo = playUrl.bestVideo!;
          final bestAudio = playUrl.bestAudio!;
          queue.add(QueueItem(
            video: video,
            audioUrl: bestAudio.baseUrl,
            qualityLabel: bestAudio.qualityLabel,
            videoUrl: bestVideo.baseUrl,
            videoQualityLabel: bestVideo.qualityLabel,
          ));
        } else {
          final streams = await _playerRepo.getAudioStreams(video.bvid);
          if (streams.isNotEmpty) {
            queue.add(QueueItem(
              video: video,
              audioUrl: streams.first.baseUrl,
              qualityLabel: streams.first.qualityLabel,
            ));
          } else {
            return false;
          }
        }
      } else {
        final streams = await _playerRepo.getAudioStreams(video.bvid);
        if (streams.isNotEmpty) {
          queue.add(QueueItem(
            video: video,
            audioUrl: streams.first.baseUrl,
            qualityLabel: streams.first.qualityLabel,
          ));
        } else {
          return false;
        }
      }

      if (!hasCurrentTrack) {
        currentIndex.value = 0;
        final item = queue[0];
        currentVideo.value = item.video;
        audioQualityLabel.value = item.qualityLabel;
        await _playQueueItem(item);
      }
      return true;
    } catch (e) {
      log('Add to queue silent failed: $e');
      return false;
    }
  }

  /// Batch add videos to the queue. Shows a single summary snackbar.
  Future<void> addAllToQueue(List<SearchVideoModel> videos) async {
    int added = 0;
    for (final video in videos) {
      final success = await addToQueueSilent(video);
      if (success) added++;
    }
    if (added > 0) {
      AppToast.show('已添加 $added 首到播放列表');
    } else {
      AppToast.show('所有歌曲已在播放列表中');
    }
  }

  /// Add a video to the queue without navigating to the player page.
  /// If nothing is currently playing, starts playback.
  Future<void> addToQueue(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      AppToast.show('已在播放列表中');
      return;
    }

    try {
      if (video.isNetease) {
        final url = await _neteaseRepo.getSongUrl(video.id);
        if (url != null && url.isNotEmpty) {
          queue.add(QueueItem(
            video: video,
            audioUrl: url,
            qualityLabel: '网易云',
          ));
        } else {
          // Fallback to Bilibili
          final fallback = await _searchBilibiliFallback(video);
          if (fallback != null) {
            AppToast.show('网易云链接不可用，已从B站换源');
            await addToQueue(fallback);
            return;
          }
        }
      } else if (_storage.enableVideo) {
        final playUrl = await _playerRepo.getFullPlayUrl(video.bvid);
        if (playUrl != null &&
            playUrl.videoStreams.isNotEmpty &&
            playUrl.bestAudio != null) {
          final bestVideo = playUrl.bestVideo!;
          final bestAudio = playUrl.bestAudio!;
          queue.add(QueueItem(
            video: video,
            audioUrl: bestAudio.baseUrl,
            qualityLabel: bestAudio.qualityLabel,
            videoUrl: bestVideo.baseUrl,
            videoQualityLabel: bestVideo.qualityLabel,
          ));
        } else {
          // Fallback to audio-only
          final streams = await _playerRepo.getAudioStreams(video.bvid);
          if (streams.isNotEmpty) {
            queue.add(QueueItem(
              video: video,
              audioUrl: streams.first.baseUrl,
              qualityLabel: streams.first.qualityLabel,
            ));
          }
        }
      } else {
        final streams = await _playerRepo.getAudioStreams(video.bvid);
        if (streams.isNotEmpty) {
          queue.add(QueueItem(
            video: video,
            audioUrl: streams.first.baseUrl,
            qualityLabel: streams.first.qualityLabel,
          ));
        }
      }

      AppToast.show('已添加到播放列表');

      // If nothing is currently playing, start playback
      if (!hasCurrentTrack) {
        currentIndex.value = 0;
        final item = queue[0];
        currentVideo.value = item.video;
        audioQualityLabel.value = item.qualityLabel;
        await _playQueueItem(item);
      }
    } catch (e) {
      log('Add to queue failed: $e');
      AppToast.error('添加失败: $e');
    }
  }
}
