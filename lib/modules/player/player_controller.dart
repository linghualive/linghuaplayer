import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../home/home_controller.dart';
import '../../data/models/music/audio_song_model.dart';
import '../../data/models/playback_info.dart';
import '../../data/models/player/lyrics_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/services/recommendation_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/sources/music_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
import '../../shared/utils/app_toast.dart';
import 'services/audio_output_service.dart';
import 'services/heart_mode_service.dart';
import 'services/media_session_service.dart';
import 'services/playback_service.dart';

enum PlayMode { sequential, shuffle, repeatOne }

class QueueItem {
  final SearchVideoModel video;
  final String audioUrl;
  final String qualityLabel;
  final String? videoUrl;
  final String? videoQualityLabel;
  final Map<String, String> headers;

  QueueItem({
    required this.video,
    required this.audioUrl,
    this.qualityLabel = '',
    this.videoUrl,
    this.videoQualityLabel,
    this.headers = const {},
  });
}

class PlayerController extends GetxController {
  final _registry = Get.find<MusicSourceRegistry>();
  final _musicRepo = Get.find<MusicRepository>();
  final _storage = Get.find<StorageService>();
  final _playback = PlaybackService();
  final _heartMode = HeartModeService();
  final audioOutput = AudioOutputService();

  // Reactive state (delegated from PlaybackService)
  final currentVideo = Rxn<SearchVideoModel>();
  final isLoading = false.obs;
  final isFullScreen = false.obs;

  RxBool get isPlaying => _playback.isPlaying;
  Rx<Duration> get position => _playback.position;
  Rx<Duration> get duration => _playback.duration;
  Rx<Duration> get buffered => _playback.buffered;
  RxBool get isVideoMode => _playback.isVideoMode;

  // Queue
  final queue = <QueueItem>[].obs;
  final currentIndex = (-1).obs;

  // Play history (for "previous track" navigation)
  final playHistory = <QueueItem>[].obs;
  static const _maxHistorySize = 50;

  // Play mode
  final playMode = PlayMode.sequential.obs;

  // Audio quality
  final audioQualityLabel = ''.obs;
  final videoQualityLabel = ''.obs;

  // Current playback source
  final currentPlaybackSourceId = 'gdstudio'.obs;

  // Related music
  final relatedMusic = <SearchVideoModel>[].obs;
  final relatedMusicLoading = false.obs;

  // Heart mode (delegated from HeartModeService)
  RxBool get isHeartMode => _heartMode.isHeartMode;
  RxList<String> get heartModeTags => _heartMode.heartModeTags;
  RxBool get isHeartModeLoading => _heartMode.isHeartModeLoading;

  // Lyrics
  final lyrics = Rxn<LyricsData>();
  final currentLyricsIndex = (-1).obs;
  final showLyrics = false.obs;
  final lyricsLoading = false.obs;

  AudioPlayer get audioPlayer => _playback.audioPlayer;
  mkv.VideoController? get videoController => _playback.videoController;

  // Listen duration tracking
  int _listenedMs = 0;
  DateTime? _playStartTime;
  int _tracksSinceBuildProfile = 0;

  // Bilibili uploader mid — preserved across cross-source fallback
  final uploaderMid = 0.obs;

  // MediaSession (mobile only)
  MediaSessionService? get _mediaSession =>
      MediaSessionService.isSupported ? Get.find<MediaSessionService>() : null;
  DateTime _lastPositionUpdate = DateTime(0);

  // Auto-play guard
  bool _hasAutoPlayed = false;

  // Manual stop guard: prevents onTrackCompleted from chaining
  // into _autoPlayNext when the stop was user-initiated.
  bool _manualStop = false;

  @override
  void onInit() {
    super.onInit();
    _playback.onTrackCompleted = _playNext;
    _playback.onPositionUpdate = _updateLyricsIndex;

    // Wire up HeartModeService callbacks
    _heartMode.onPlayFromSearch = playFromSearch;
    _heartMode.onAddToQueueSilent = addToQueueSilent;
    _heartMode.onStopPlayback = _playback.stop;
    _heartMode.getCurrentQueue = () => List.from(queue);
    _heartMode.getCurrentVideo = () => currentVideo.value;
    _heartMode.onRestoreQueue = _restoreQueue;

    // Track listen duration across play/pause transitions
    ever(isPlaying, (bool playing) {
      if (playing) {
        _playStartTime = DateTime.now();
        // Connect NativePlayer to AudioOutputService when playback starts (desktop)
        _connectAudioOutputIfNeeded();
      } else if (_playStartTime != null) {
        _listenedMs += DateTime.now().difference(_playStartTime!).inMilliseconds;
        _playStartTime = null;
      }
    });

    // MediaSession integration (mobile only)
    _initMediaSession();
  }

  void _initMediaSession() {
    final ms = _mediaSession;
    if (ms == null) return;

    // Bind OS media button callbacks
    ms.onPlayCallback = () => _playback.play();
    ms.onPauseCallback = () => _playback.pause();
    ms.onSkipNextCallback = () => skipNext();
    ms.onSkipPreviousCallback = () => skipPrevious();
    ms.onStopCallback = () => clearQueue();
    ms.onSeekToCallback = (pos) => _playback.seekTo(pos);

    // Push play/pause state changes
    ever(isPlaying, (bool playing) {
      ms.updatePlaybackState(
        playing: playing,
        position: position.value,
        bufferedPosition: buffered.value,
      );
    });

    // Push position updates (throttled to 1s)
    ever(position, (Duration pos) {
      final now = DateTime.now();
      if (now.difference(_lastPositionUpdate).inMilliseconds < 1000) return;
      _lastPositionUpdate = now;
      ms.updatePlaybackState(
        playing: isPlaying.value,
        position: pos,
        bufferedPosition: buffered.value,
      );
    });

    // Push metadata when current video changes
    ever(currentVideo, (SearchVideoModel? video) {
      if (video == null) {
        ms.setIdle();
        return;
      }
      ms.setMediaMetadata(
        title: video.title,
        artist: video.author,
        artUri: video.pic,
        duration: duration.value > Duration.zero ? duration.value : null,
      );
    });

    // Update duration in metadata when it becomes available
    ever(duration, (Duration dur) {
      final video = currentVideo.value;
      if (video == null || dur <= Duration.zero) return;
      ms.setMediaMetadata(
        title: video.title,
        artist: video.author,
        artUri: video.pic,
        duration: dur,
      );
    });
  }

  void _connectAudioOutputIfNeeded() {
    final nativePlayer = _playback.nativePlayerRef;
    if (nativePlayer != null) {
      audioOutput.connectNativePlayer(nativePlayer);
    }
  }

  @override
  void onClose() {
    _mediaSession?.setIdle();
    _playback.dispose();
    super.onClose();
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

  /// Push the current song to the play history stack.
  void _pushToHistory() {
    if (queue.isEmpty || currentIndex.value < 0) return;
    final current = queue[0];
    playHistory.add(current);
    if (playHistory.length > _maxHistorySize) {
      playHistory.removeAt(0);
    }
  }

  /// Save accumulated listen duration for the current track, then reset.
  void _saveListenDuration() {
    // Flush any in-progress playing time
    if (_playStartTime != null) {
      _listenedMs += DateTime.now().difference(_playStartTime!).inMilliseconds;
      _playStartTime = null;
    }
    if (_listenedMs > 0 && currentVideo.value != null) {
      _storage.updatePlayDuration(currentVideo.value!.uniqueId, _listenedMs);
      _tracksSinceBuildProfile++;
      if (_tracksSinceBuildProfile >= 5) {
        _tracksSinceBuildProfile = 0;
        try {
          final profileService = Get.find<UserProfileService>();
          profileService.buildProfile();
        } catch (_) {}
      }
    }
    _listenedMs = 0;
  }

  /// Play from search result and navigate to player page.
  ///
  /// [preferredSourceId] specifies which source to try first.
  /// Defaults to 'gdstudio' so search/recommendation results play via GD.
  /// Pass `null` to use the track's own source (e.g. from favorites).
  Future<void> playFromSearch(
    SearchVideoModel video, {
    String? preferredSourceId = 'gdstudio',
  }) async {
    _saveListenDuration();
    isLoading.value = true;
    currentVideo.value = video;

    // Preserve the original Bilibili uploader mid before fallback
    _updateUploaderMid(video);

    _navigateToPlayer();

    try {
      final resolved = await _registry.resolvePlaybackWithFallback(
        video,
        videoMode: _storage.enableVideo,
        preferredSourceId: preferredSourceId,
      );

      if (resolved == null) {
        throw Exception('无法获取播放链接');
      }

      final (info, resolvedVideo) = resolved;

      // If fallback occurred, update the current video
      if (resolvedVideo.uniqueId != video.uniqueId) {
        currentVideo.value = resolvedVideo;
      }

      currentPlaybackSourceId.value = info.sourceId;
      await _playFromInfo(info, resolvedVideo);
      _storage.addPlayHistory(resolvedVideo);
    } catch (e) {
      log('Playback failed: $e');
      AppToast.error('播放失败: $e');
    }
    isLoading.value = false;
    _fetchLyrics(currentVideo.value ?? video);
    _loadRelatedMusic(currentVideo.value ?? video);
  }

  /// Switch the current song's playback source manually.
  ///
  /// Re-resolves the current track via the specified source and replays.
  Future<void> switchPlaybackSource(String sourceId) async {
    final video = currentVideo.value;
    if (video == null) return;

    isLoading.value = true;
    try {
      final resolved = await _registry.resolvePlaybackWithFallback(
        video,
        videoMode: _storage.enableVideo,
        preferredSourceId: sourceId,
        enableFallback: false,
      );

      if (resolved == null) {
        AppToast.error('该音乐源无法播放此歌曲');
        isLoading.value = false;
        return;
      }

      final (info, resolvedVideo) = resolved;
      currentPlaybackSourceId.value = info.sourceId;

      if (resolvedVideo.uniqueId != video.uniqueId) {
        currentVideo.value = resolvedVideo;
      }

      await _playFromInfo(info, resolvedVideo);
      _fetchLyrics(resolvedVideo);
      AppToast.show('已切换到 ${_registry.getSource(info.sourceId)?.displayName ?? info.sourceId}');
    } catch (e) {
      log('Switch source failed: $e');
      AppToast.error('切换音乐源失败');
    }
    isLoading.value = false;
  }

  /// Unified playback from resolved PlaybackInfo.
  Future<void> _playFromInfo(PlaybackInfo info, SearchVideoModel video) async {
    final bestAudio = info.bestAudio;
    if (bestAudio == null) throw Exception('No audio stream available');

    if (info.hasVideo && _storage.enableVideo) {
      await _playback.prepareForVideo();
      final bestVideo = info.bestVideo!;
      audioQualityLabel.value = bestAudio.qualityLabel;
      videoQualityLabel.value = bestVideo.qualityLabel;
      await _playback.playVideoWithAudio(bestVideo.url, bestAudio.url);

      _addToQueue(
        video: video,
        audioUrl: bestAudio.url,
        qualityLabel: bestAudio.qualityLabel,
        videoUrl: bestVideo.url,
        videoQualityLabel: bestVideo.qualityLabel,
        headers: bestAudio.headers,
      );
    } else {
      _playback.prepareForAudioOnly();

      // Try audio streams with fallback through backup URLs
      String? playedUrl;
      String playedLabel = '';
      for (final stream in info.audioStreams) {
        try {
          await _playback.playAudioWithHeaders(stream.url, stream.headers);
          playedUrl = stream.url;
          playedLabel = stream.qualityLabel;
          break;
        } catch (e) {
          log('Audio stream ${stream.qualityLabel} failed: $e');
          if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
            try {
              await _playback.playAudioWithHeaders(
                  stream.backupUrl!, stream.headers);
              playedUrl = stream.backupUrl!;
              playedLabel = stream.qualityLabel;
              break;
            } catch (e2) {
              log('Audio stream ${stream.qualityLabel} backup failed: $e2');
            }
          }
        }
      }

      if (playedUrl == null) throw Exception('All audio streams failed');

      audioQualityLabel.value = playedLabel;
      videoQualityLabel.value = '';

      _addToQueue(
        video: video,
        audioUrl: playedUrl,
        qualityLabel: playedLabel,
        headers: bestAudio.headers,
      );
    }
  }

  /// Auto-play a random song (called when player tab opens with empty queue).
  Future<void> playRandomIfNeeded() async {
    if (_hasAutoPlayed || currentVideo.value != null || isLoading.value) return;
    _hasAutoPlayed = true;

    // 1. Try personalized recommendations using preference tags
    final tags = _storage.preferenceTags;
    if (tags.isNotEmpty) {
      try {
        final recService = Get.find<RecommendationService>();
        final recentHistory = _storage
            .getPlayHistory()
            .take(20)
            .map((e) {
              final v = SearchVideoModel.fromJson(
                  e['video'] as Map<String, dynamic>);
              return '${v.title} - ${v.author}';
            })
            .toList();

        final songs = await recService.getRecommendations(
          tags: tags,
          recentPlayed: recentHistory,
        );
        if (songs.isNotEmpty) {
          await playFromSearch(songs.first);
          for (int i = 1; i < songs.length && i < 5; i++) {
            await addToQueueSilent(songs[i]);
          }
          return;
        }
      } catch (e) {
        log('Personalized auto-play failed: $e');
      }
    }

    // 2. Fallback to random keyword search via music-only sources
    //    (skip Bilibili — its search returns all video types, not just music)
    const keywords = [
      '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
      '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    ];
    final random = Random();
    final keyword = keywords[random.nextInt(keywords.length)];

    try {
      final musicSources = _registry.availableSources
          .where((s) => s.sourceId != 'bilibili')
          .toList();
      for (final source in musicSources) {
        final result = await source.searchTracks(keyword: keyword, limit: 10);
        if (result.tracks.isNotEmpty) {
          final maxIndex = result.tracks.length.clamp(1, 5);
          final video = result.tracks[random.nextInt(maxIndex)];
          await playFromSearch(video);
          return;
        }
      }
    } catch (e) {
      log('playRandomIfNeeded error: $e');
    }
  }

  void _addToQueue({
    required SearchVideoModel video,
    required String audioUrl,
    String qualityLabel = '',
    String? videoUrl,
    String? videoQualityLabel,
    Map<String, String> headers = const {},
  }) {
    final queueItem = QueueItem(
      video: video,
      audioUrl: audioUrl,
      qualityLabel: qualityLabel,
      videoUrl: videoUrl,
      videoQualityLabel: videoQualityLabel,
      headers: headers,
    );

    // Push current song to history before replacing
    _pushToHistory();

    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      queue.removeAt(existingIndex);
    }
    queue.insert(0, queueItem);
    currentIndex.value = 0;
  }

  Future<void> _playQueueItem(QueueItem item) async {
    if (item.videoUrl != null && _storage.enableVideo) {
      videoQualityLabel.value = item.videoQualityLabel ?? '';
      await _playback.playVideoWithAudio(item.videoUrl!, item.audioUrl);
    } else {
      await _playback.ensureMediaKit();
      _playback.isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playback.playAudioWithHeaders(item.audioUrl, item.headers);
    }
  }

  /// Switch the current track between video and audio-only mode.
  Future<void> toggleVideoMode() async {
    if (currentIndex.value < 0 || currentIndex.value >= queue.length) return;
    final item = queue[currentIndex.value];

    // Check if source supports video
    final source = _registry.getSourceForTrack(item.video);
    if (source is! VideoCapability || !source.hasVideo(item.video)) {
      AppToast.show('该音乐源暂不支持视频模式');
      return;
    }
    final currentPos = position.value;

    try {
      if (isVideoMode.value) {
        // Switch to audio-only
        _playback.prepareForAudioOnly();
        videoQualityLabel.value = '';
        await _playback.playAudioWithHeaders(item.audioUrl, item.headers);
        if (currentPos > Duration.zero) {
          await Future.delayed(const Duration(milliseconds: 200));
          _playback.seekTo(currentPos);
        }
      } else {
        // Switch to video
        if (item.videoUrl != null) {
          videoQualityLabel.value = item.videoQualityLabel ?? '';
          await _playback.prepareForVideo();
          await _playback.playVideoWithAudio(item.videoUrl!, item.audioUrl);
          if (currentPos > Duration.zero) {
            await Future.delayed(const Duration(milliseconds: 500));
            _playback.seekTo(currentPos);
          }
        } else {
          // No video URL cached, resolve with video mode
          final info = await source.resolvePlayback(item.video, videoMode: true);
          if (info != null && info.hasVideo && info.bestAudio != null) {
            final bestVideo = info.bestVideo!;
            final bestAudio = info.bestAudio!;
            final newItem = QueueItem(
              video: item.video,
              audioUrl: bestAudio.url,
              qualityLabel: bestAudio.qualityLabel,
              videoUrl: bestVideo.url,
              videoQualityLabel: bestVideo.qualityLabel,
              headers: bestAudio.headers,
            );
            queue[currentIndex.value] = newItem;

            audioQualityLabel.value = bestAudio.qualityLabel;
            videoQualityLabel.value = bestVideo.qualityLabel;
            await _playback.prepareForVideo();
            await _playback.playVideoWithAudio(bestVideo.url, bestAudio.url);
            if (currentPos > Duration.zero) {
              await Future.delayed(const Duration(milliseconds: 500));
              _playback.seekTo(currentPos);
            }
          } else {
            AppToast.show('该视频无画面资源');
          }
        }
      }
    } catch (e) {
      log('toggleVideoMode error: $e');
      AppToast.error('视频模式切换失败');
      // Fallback: ensure audio keeps playing
      _playback.prepareForAudioOnly();
      videoQualityLabel.value = '';
    }
  }

  void togglePlay() => _playback.togglePlay();

  void seekTo(Duration pos) => _playback.seekTo(pos);

  void _playNext() {
    // Ignore completion events caused by manual stop/skip
    if (_manualStop) {
      _manualStop = false;
      return;
    }
    if (_heartMode.handleTrackCompleted()) return;

    switch (playMode.value) {
      case PlayMode.repeatOne:
        _playback.seekTo(Duration.zero);
        _playback.play();
        break;
      case PlayMode.shuffle:
        if (queue.length <= 1) {
          _autoPlayNext();
          return;
        }
        final rng = Random();
        final next = 1 + rng.nextInt(queue.length - 1);
        playAt(next);
        break;
      case PlayMode.sequential:
        _advanceNext();
        break;
    }
  }

  Future<void> _autoPlayNext() async {
    if (_heartMode.isHeartMode.value) {
      await _heartMode.autoNext();
      return;
    }

    final video = currentVideo.value;
    if (video == null) {
      _hasAutoPlayed = false;
      await playRandomIfNeeded();
      return;
    }

    final rng = Random();

    // Exclude both queue and recently played history to avoid ping-ponging
    final excludeIds = <String>{
      ...queue.map((q) => q.video.uniqueId),
      ...playHistory.map((q) => q.video.uniqueId),
      video.uniqueId,
    };

    // Also exclude by normalized title to avoid the same song from different sources
    final excludeTitles = <String>{
      _normalizeTitle(video.title),
      ...queue.map((q) => _normalizeTitle(q.video.title)),
      ...playHistory.map((q) => _normalizeTitle(q.video.title)),
    };

    bool _isExcluded(SearchVideoModel s) =>
        excludeIds.contains(s.uniqueId) ||
        excludeTitles.contains(_normalizeTitle(s.title));

    // 1. Try related music not already played (random pick)
    final candidates = relatedMusic.where((s) => !_isExcluded(s)).toList();

    if (candidates.isNotEmpty) {
      final pick = candidates[rng.nextInt(candidates.length)];
      AppToast.show('已为你自动推荐');
      await playFromSearch(pick);
      return;
    }

    // 2. Discover more songs via varied search strategies
    try {
      final source = _registry.getSourceForTrack(video);
      if (source != null) {
        final moreSongs = await _getVariedRelatedTracks(source, video, rng);
        final filtered = moreSongs.where((s) => !_isExcluded(s)).toList();
        if (filtered.isNotEmpty) {
          final pick = filtered[rng.nextInt(filtered.length)];
          AppToast.show('已为你自动推荐');
          await playFromSearch(pick);
          return;
        }
      }
    } catch (e) {
      log('Auto-play discover error: $e');
    }

    // 3. Try cross-source discovery with varied keywords
    try {
      final crossResult = await _crossSourceDiscover(video, _isExcluded, rng);
      if (crossResult != null) {
        AppToast.show('已为你自动推荐');
        await playFromSearch(crossResult);
        return;
      }
    } catch (e) {
      log('Auto-play cross-source error: $e');
    }

    // 4. Nothing left, stop
    _manualStop = true;
    _playback.stop();
  }

  /// Search for related tracks using varied keywords to avoid returning
  /// the same results every time.
  Future<List<SearchVideoModel>> _getVariedRelatedTracks(
    MusicSourceAdapter source,
    SearchVideoModel video,
    Random rng,
  ) async {
    final strategies = <String>[];

    // Strategy variations based on available metadata
    if (video.author.isNotEmpty) {
      strategies.add(video.author); // just artist name
      strategies.add('${video.author} 热门');
      strategies.add('${video.author} 精选');
    }
    if (video.title.isNotEmpty) {
      // Use title keywords (first few chars to find similar songs)
      final titleKeyword = video.title.length > 4
          ? video.title.substring(0, 4)
          : video.title;
      strategies.add(titleKeyword);
    }
    if (video.description.isNotEmpty && video.description.length > 1) {
      // Search by album name
      strategies.add(video.description);
    }

    // Shuffle and try each strategy
    strategies.shuffle(rng);

    for (final keyword in strategies) {
      try {
        final result = await source.searchTracks(
          keyword: keyword,
          limit: 20,
          offset: rng.nextInt(3) * 20, // random page for variety
        );
        if (result.tracks.isNotEmpty) return result.tracks;
      } catch (_) {}
    }

    return [];
  }

  /// Try discovering songs from other sources when the current source
  /// is exhausted.
  Future<SearchVideoModel?> _crossSourceDiscover(
    SearchVideoModel video,
    bool Function(SearchVideoModel) isExcluded,
    Random rng,
  ) async {
    // Build varied keywords from recent play history
    final recentTitles = playHistory
        .take(5)
        .map((q) => q.video.author)
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();

    final keywords = <String>[
      if (video.author.isNotEmpty) video.author,
      ...recentTitles,
      // Generic discovery keywords as last resort
      '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
      '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    ];
    keywords.shuffle(rng);

    final sources = _registry.availableSources
        .where((s) => s.sourceId != 'bilibili')
        .toList()
      ..shuffle(rng);

    for (final keyword in keywords.take(4)) {
      for (final source in sources) {
        try {
          final result = await source.searchTracks(
            keyword: keyword,
            limit: 15,
            offset: rng.nextInt(2) * 15,
          );
          final filtered =
              result.tracks.where((s) => !isExcluded(s)).toList();
          if (filtered.isNotEmpty) {
            return filtered[rng.nextInt(filtered.length)];
          }
        } catch (_) {}
      }
    }
    return null;
  }

  // ── Heart Mode ──

  Future<void> activateHeartMode(List<String> tags) async {
    queue.clear();
    currentIndex.value = -1;
    await _heartMode.activate(tags);
  }

  void deactivateHeartMode() => _heartMode.deactivate();

  void toggleHeartMode() => _heartMode.toggle();

  /// Called by HeartModeService to restore the queue after exiting heart mode.
  void _restoreQueue(
      List<QueueItem> savedQueue, int index, SearchVideoModel? video) {
    queue.assignAll(savedQueue);
    currentIndex.value = index;

    if (savedQueue.isNotEmpty) {
      final item = queue[0];
      currentVideo.value = item.video;
      _updateUploaderMid(item.video);
      _playQueueItem(item);
    } else {
      currentVideo.value = video;
      if (video != null) _updateUploaderMid(video);
      _playback.stop();
    }
  }

  /// User manually skips: remove current song from queue, then play next.
  /// If queue is empty, just stop — don't auto-recommend.
  Future<void> skipNext() async {
    _saveListenDuration();
    if (queue.length > 1) {
      _pushToHistory();
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      _updateUploaderMid(item.video);
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
      _loadRelatedMusic(item.video);
    } else {
      // Queue has no next song — auto-recommend (history-aware, won't ping-pong)
      _autoPlayNext();
    }
  }

  /// Auto-advance when track finishes: move current to history, play next.
  Future<void> _advanceNext() async {
    _saveListenDuration();
    if (queue.length > 1) {
      _pushToHistory();
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      _updateUploaderMid(item.video);
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
      _loadRelatedMusic(item.video);
    } else {
      _autoPlayNext();
    }
  }

  Future<void> skipPrevious() async {
    _saveListenDuration();
    // If played more than 3 seconds, restart current track
    if (currentVideo.value != null && position.value.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }
    // Go back to previous song from history
    if (playHistory.isNotEmpty) {
      final previous = playHistory.removeLast();
      // Current song goes back to the front of the queue
      queue.insert(0, previous);
      currentIndex.value = 0;
      currentVideo.value = previous.video;
      _updateUploaderMid(previous.video);
      audioQualityLabel.value = previous.qualityLabel;

      await _playQueueItem(previous);
      _fetchLyrics(previous.video);
      _loadRelatedMusic(previous.video);
    } else {
      // No history, just restart current track
      seekTo(Duration.zero);
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
    _saveListenDuration();
    if (index == 0) {
      // Already playing this song, restart
      seekTo(Duration.zero);
      _playback.play();
      return;
    }
    _pushToHistory();
    queue.removeAt(0);
    // Target is now at index - 1
    final item = queue.removeAt(index - 1);
    queue.insert(0, item);
    currentIndex.value = 0;
    currentVideo.value = item.video;
    _updateUploaderMid(item.video);
    audioQualityLabel.value = item.qualityLabel;
    await _playQueueItem(item);
    _fetchLyrics(item.video);
    _loadRelatedMusic(item.video);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
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
    if (index == 0) return;
    queue.removeAt(index);
  }

  void clearQueue() {
    _saveListenDuration();
    _manualStop = true;
    _playback.stop();
    _playback.isVideoMode.value = false;
    queue.clear();
    playHistory.clear();
    currentIndex.value = -1;
    currentVideo.value = null;
    uploaderMid.value = 0;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    lyrics.value = null;
    currentLyricsIndex.value = -1;
    showLyrics.value = false;
    lyricsLoading.value = false;
    relatedMusic.clear();
    relatedMusicLoading.value = false;
    _mediaSession?.setIdle();
  }

  // -- Related Music --

  void _loadRelatedMusic(SearchVideoModel video) {
    relatedMusic.clear();
    relatedMusicLoading.value = true;

    final source = _registry.getSourceForTrack(video);
    if (source == null) {
      relatedMusicLoading.value = false;
      return;
    }

    source.getRelatedTracks(video).then((results) {
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        // Deduplicate by normalized title
        final seen = <String>{_normalizeTitle(video.title)};
        final deduped = results
            .where((s) => seen.add(_normalizeTitle(s.title)))
            .toList();
        // Filter out songs already in queue or recently played
        final excludeIds = <String>{
          ...queue.map((q) => q.video.uniqueId),
          ...playHistory.map((q) => q.video.uniqueId),
        };
        final filtered =
            deduped.where((s) => !excludeIds.contains(s.uniqueId)).toList();
        // Shuffle for variety so auto-play doesn't always pick the same order
        filtered.shuffle();
        relatedMusic.assignAll(filtered);
        relatedMusicLoading.value = false;
      }
    }).catchError((e) {
      log('Related music fetch error: $e');
      if (currentVideo.value?.uniqueId == video.uniqueId) {
        relatedMusicLoading.value = false;
      }
    });
  }

  /// Update the preserved Bilibili uploader mid from a video.
  void _updateUploaderMid(SearchVideoModel video) {
    if (video.isBilibili && video.mid > 0) {
      uploaderMid.value = video.mid;
    } else {
      uploaderMid.value = 0;
    }
  }

  /// Load uploader's seasons/series (合集) — Bilibili-specific
  Future<MemberSeasonsResult> loadUploaderSeasons() async {
    final mid = uploaderMid.value;
    if (mid <= 0) {
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }

    try {
      return await _musicRepo.getMemberSeasons(mid);
    } catch (e) {
      log('Uploader seasons fetch error: $e');
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }
  }

  /// Load one page of videos in a collection (合集 or 系列) — Bilibili-specific
  Future<CollectionPage> loadCollectionPage(
      MemberSeason season, {int pn = 1}) async {
    final mid = uploaderMid.value;
    if (mid <= 0) {
      return CollectionPage(items: [], total: 0);
    }

    try {
      if (season.category == 0 && season.seasonId > 0) {
        return await _musicRepo.getSeasonDetail(
          mid: mid,
          seasonId: season.seasonId,
          pn: pn,
        );
      } else if (season.seriesId > 0) {
        return await _musicRepo.getSeriesDetail(
          mid: mid,
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

    final source = _registry.getSourceForTrack(video);
    final Future<LyricsData?> fetchFuture;

    if (source is LyricsCapability) {
      fetchFuture = source.getLyrics(video);
    } else {
      lyricsLoading.value = false;
      return;
    }

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

  /// Normalize a song title for fuzzy deduplication.
  static String _normalizeTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'（.*?）'), '')
        .replaceAll(RegExp(r'【.*?】'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  /// Play from an AU audio song (Bilibili audio channel).
  Future<void> playFromAudioSong(AudioSongModel song) async {
    final video = song.toSearchVideoModel();
    isLoading.value = true;
    currentVideo.value = video;
    _updateUploaderMid(video);

    _navigateToPlayer();

    try {
      final audioUrl = await _musicRepo.getAudioUrl(song.id);

      if (audioUrl != null && audioUrl.isNotEmpty) {
        _playback.prepareForAudioOnly();
        await _playback.playBilibiliAudio(audioUrl);
        audioQualityLabel.value = 'AU';
        videoQualityLabel.value = '';

        _addToQueue(
          video: video,
          audioUrl: audioUrl,
          qualityLabel: 'AU',
        );
      } else if (video.bvid.isNotEmpty) {
        // Fallback to normal Bilibili playback via adapter
        final resolved = await _registry.resolvePlaybackWithFallback(
          video,
          videoMode: false,
          enableFallback: false,
        );
        if (resolved != null) {
          await _playFromInfo(resolved.$1, resolved.$2);
        } else {
          throw Exception('No playable URL');
        }
      } else {
        throw Exception('No playable URL');
      }
      _storage.addPlayHistory(video);
    } catch (e) {
      log('AU playback failed: $e');
      AppToast.error('播放失败: $e');
    }
    isLoading.value = false;
    _fetchLyrics(video);
    _loadRelatedMusic(video);
  }

  // ── Queue Resolution (shared by addToQueue and addToQueueSilent) ──

  Future<QueueItem?> _resolveQueueItem(SearchVideoModel video) async {
    final resolved = await _registry.resolvePlaybackWithFallback(
      video,
      videoMode: _storage.enableVideo,
    );
    if (resolved == null) return null;

    final (info, resolvedVideo) = resolved;
    final bestAudio = info.bestAudio;
    if (bestAudio == null) return null;

    if (info.hasVideo && _storage.enableVideo) {
      final bestVideo = info.bestVideo!;
      return QueueItem(
        video: resolvedVideo,
        audioUrl: bestAudio.url,
        qualityLabel: bestAudio.qualityLabel,
        videoUrl: bestVideo.url,
        videoQualityLabel: bestVideo.qualityLabel,
        headers: bestAudio.headers,
      );
    }

    return QueueItem(
      video: resolvedVideo,
      audioUrl: bestAudio.url,
      qualityLabel: bestAudio.qualityLabel,
      headers: bestAudio.headers,
    );
  }

  Future<void> _startPlaybackIfIdle() async {
    if (!hasCurrentTrack && queue.isNotEmpty) {
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      _updateUploaderMid(item.video);
      audioQualityLabel.value = item.qualityLabel;
      await _playQueueItem(item);
    }
  }

  /// Add a video to the queue silently (no snackbar).
  Future<bool> addToQueueSilent(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) return false;

    try {
      final item = await _resolveQueueItem(video);
      if (item == null) return false;
      queue.add(item);
      await _startPlaybackIfIdle();
      return true;
    } catch (e) {
      log('Add to queue silent failed: $e');
      return false;
    }
  }

  /// Batch add videos to the queue.
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
  Future<void> addToQueue(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      AppToast.show('已在播放列表中');
      return;
    }

    try {
      final item = await _resolveQueueItem(video);
      if (item == null) return;

      // Check if a fallback occurred (resolved video differs from input)
      if (item.video.uniqueId != video.uniqueId) {
        log('Source fallback occurred for "${video.title}"');
      }

      queue.add(item);
      AppToast.show('已添加到播放列表');
      await _startPlaybackIfIdle();
    } catch (e) {
      log('Add to queue failed: $e');
      AppToast.error('添加失败: $e');
    }
  }
}
