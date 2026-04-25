import 'dart:developer';
import 'dart:math' show Random;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/routes/app_routes.dart';
import '../../core/http/http_client.dart';
import '../../core/storage/storage_service.dart';
import '../home/home_controller.dart';
import '../../data/models/music/audio_song_model.dart';
import '../../data/models/playback_info.dart';
import '../../data/models/player/lyrics_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/sources/music_source_adapter.dart' show LyricsCapability;
import '../../data/sources/music_source_registry.dart';
import '../../shared/utils/app_toast.dart';
import 'services/audio_output_service.dart';
import 'services/cover_color_service.dart';
import 'services/media_session_service.dart';
import 'services/playback_service.dart';

enum PlayMode { sequential, shuffle, repeatOne }

class QueueItem {
  final SearchVideoModel video;
  final String audioUrl;
  final String qualityLabel;
  final Map<String, String> headers;

  QueueItem({
    required this.video,
    required this.audioUrl,
    this.qualityLabel = '',
    this.headers = const {},
  });

  Map<String, dynamic> toJson() => {
        'video': video.toJson(),
        'audioUrl': audioUrl,
        'qualityLabel': qualityLabel,
        'headers': headers,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      video: SearchVideoModel.fromJson(
          json['video'] as Map<String, dynamic>? ?? {}),
      audioUrl: json['audioUrl'] as String? ?? '',
      qualityLabel: json['qualityLabel'] as String? ?? '',
      headers: (json['headers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
    );
  }
}

class PlayerController extends GetxController {
  final _registry = Get.find<MusicSourceRegistry>();
  final _musicRepo = Get.find<MusicRepository>();
  final _storage = Get.find<StorageService>();
  final _playback = PlaybackService();
  final audioOutput = AudioOutputService();

  // Reactive state (delegated from PlaybackService)
  final currentVideo = Rxn<SearchVideoModel>();
  final isLoading = false.obs;

  RxBool get isPlaying => _playback.isPlaying;
  Rx<Duration> get position => _playback.position;
  Rx<Duration> get duration => _playback.duration;
  Rx<Duration> get buffered => _playback.buffered;

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

  // Current playback source
  final currentPlaybackSourceId = 'gdstudio'.obs;

  // Related music
  final relatedMusic = <SearchVideoModel>[].obs;
  final relatedMusicLoading = false.obs;

  // Lyrics
  final lyrics = Rxn<LyricsData>();
  final currentLyricsIndex = (-1).obs;
  final showLyrics = false.obs;
  final lyricsLoading = false.obs;

  AudioPlayer get audioPlayer => _playback.audioPlayer;

  // Listen duration tracking
  int _listenedMs = 0;
  DateTime? _playStartTime;
  int _tracksSinceBuildProfile = 0;

  // Cover dominant color (extracted from album art)
  final coverColor = Rxn<Color>();
  final _coverColorService = CoverColorService();
  int _colorGeneration = 0;

  // Bilibili uploader mid — preserved across cross-source fallback
  final uploaderMid = 0.obs;

  // MediaSession (mobile only)
  MediaSessionService? get _mediaSession =>
      MediaSessionService.isSupported ? Get.find<MediaSessionService>() : null;
  DateTime _lastPositionUpdate = DateTime(0);

  // Manual stop guard: prevents onTrackCompleted from chaining
  // into _advanceNext when the stop was user-initiated.
  bool _manualStop = false;

  // Generation counter for playFromSearch cancellation:
  // each new call increments this, and stale requests bail out.
  int _playGeneration = 0;

  // ── Playback URL Resolution Cache ──
  // Caches (PlaybackInfo, SearchVideoModel) by uniqueId to avoid
  // repeated network calls for recently resolved songs.
  final _resolveCache = <String, _CachedResolve>{};
  static const _resolveCacheTtl = Duration(minutes: 10);
  static const _maxCacheSize = 100;

  @override
  void onInit() {
    super.onInit();
    _playback.onTrackCompleted = _playNext;
    _playback.onPositionUpdate = _updateLyricsIndex;
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

    // Extract dominant color from cover art
    ever(currentVideo, _extractCoverColor);

    // MediaSession integration (mobile only)
    _initMediaSession();
  }

  Future<void> _extractCoverColor(SearchVideoModel? video) async {
    final gen = ++_colorGeneration;
    if (video == null || video.pic.isEmpty) {
      coverColor.value = null;
      return;
    }
    final color = await _coverColorService.extractDominantColor(video.pic);
    if (_colorGeneration == gen) {
      coverColor.value = color;
    }
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

  // ── Cache helpers ──

  (PlaybackInfo, SearchVideoModel)? _getCachedResolve(String uniqueId) {
    final entry = _resolveCache[uniqueId];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _resolveCacheTtl) {
      _resolveCache.remove(uniqueId);
      return null;
    }
    return (entry.info, entry.resolvedVideo);
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    _resolveCache.removeWhere(
        (_, entry) => now.difference(entry.cachedAt) > _resolveCacheTtl);
  }

  void _putCachedResolve(
      String uniqueId, PlaybackInfo info, SearchVideoModel video) {
    _cleanExpiredCache();
    _resolveCache[uniqueId] = _CachedResolve(info, video);
    // Evict oldest if over capacity (Map preserves insertion order)
    while (_resolveCache.length > _maxCacheSize) {
      _resolveCache.remove(_resolveCache.keys.first);
    }
  }

  /// Play from search result and navigate to player page.
  ///
  /// [preferredSourceId] specifies which source to try first.
  /// Defaults to `null` which uses the track's own source.
  Future<void> playFromSearch(
    SearchVideoModel video, {
    String? preferredSourceId,
    bool navigate = true,
  }) async {
    // Increment generation to cancel any in-flight playFromSearch
    final gen = ++_playGeneration;

    _saveListenDuration();

    // Stop current playback immediately
    _manualStop = true;
    _playback.stop();
    isLoading.value = true;

    currentVideo.value = video;
    _updateUploaderMid(video);
    if (navigate) _navigateToPlayer();

    // ── Fast path 1: song already in queue ──
    final queuedIndex =
        queue.indexWhere((q) => q.video.uniqueId == video.uniqueId);
    if (queuedIndex >= 0) {
      if (queuedIndex > 0) _pushToHistory();
      final item = queue.removeAt(queuedIndex);
      queue.insert(0, item);
      currentIndex.value = 0;
      _manualStop = false;
      audioQualityLabel.value = item.qualityLabel;
      try {
        await _playQueueItem(item, gen: gen);
        if (gen != _playGeneration) return;
        final played = queue.isNotEmpty ? queue[0].video : item.video;
        _storage.addPlayHistory(played);
        _fetchLyrics(played);
        _loadRelatedMusic(played);
      } catch (e) {
        if (gen != _playGeneration) return;
        _manualStop = false;
        log('Playback failed (queued): $e');
        AppToast.error('播放失败: $e');
      }
      if (gen != _playGeneration) return;
      isLoading.value = false;
      return;
    }

    // ── Fast path 2: URL in resolve cache ──
    final cached = _getCachedResolve(video.uniqueId);
    if (cached != null) {
      try {
        final (info, resolvedVideo) = cached;
        if (resolvedVideo.uniqueId != video.uniqueId) {
          currentVideo.value = resolvedVideo;
        }
        currentPlaybackSourceId.value = info.sourceId;
        await _playFromInfo(info, resolvedVideo, gen: gen);
        if (gen != _playGeneration) return;
        _storage.addPlayHistory(resolvedVideo);
        isLoading.value = false;
        _fetchLyrics(currentVideo.value ?? video);
        _loadRelatedMusic(currentVideo.value ?? video);
            return;
      } catch (_) {
        // Cache hit but playback failed — fall through to normal resolve
        _resolveCache.remove(video.uniqueId);
      }
    }

    // ── Normal path: resolve URL from network ──
    try {
      final resolved = await _registry.resolvePlaybackWithFallback(
        video,
        preferredSourceId: preferredSourceId,
      );

      if (gen != _playGeneration) return;

      if (resolved == null) {
        throw Exception('无法获取播放链接');
      }

      final (info, resolvedVideo) = resolved;

      // Cache the resolution for future use
      _putCachedResolve(video.uniqueId, info, resolvedVideo);

      if (resolvedVideo.uniqueId != video.uniqueId) {
        currentVideo.value = resolvedVideo;
      }

      currentPlaybackSourceId.value = info.sourceId;
      await _playFromInfo(info, resolvedVideo, gen: gen);

      if (gen != _playGeneration) return;

      _storage.addPlayHistory(resolvedVideo);
    } catch (e) {
      if (gen != _playGeneration) return;
      _manualStop = false;
      log('Playback failed: $e');
      AppToast.error('播放失败: $e');
    }
    if (gen != _playGeneration) return;
    isLoading.value = false;
    _fetchLyrics(currentVideo.value ?? video);
    _loadRelatedMusic(currentVideo.value ?? video);
  }

  /// Switch the current song's playback source manually.
  ///
  /// Re-resolves the current track via the specified source and replays.
  Future<void> switchPlaybackSource(String sourceId) async {
    final gen = ++_playGeneration;
    final video = currentVideo.value;
    if (video == null) return;

    isLoading.value = true;
    try {
      final resolved = await _registry.resolvePlaybackWithFallback(
        video,
        preferredSourceId: sourceId,
        enableFallback: false,
      );

      if (gen != _playGeneration) return;

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

      await _playFromInfo(info, resolvedVideo, gen: gen);
      if (gen != _playGeneration) return;
      _fetchLyrics(resolvedVideo);
      AppToast.show('已切换到 ${_registry.getSource(info.sourceId)?.displayName ?? info.sourceId}');
    } catch (e) {
      if (gen != _playGeneration) return;
      log('Switch source failed: $e');
      AppToast.error('切换音乐源失败');
    }
    if (gen != _playGeneration) return;
    isLoading.value = false;
  }

  /// Unified playback from resolved PlaybackInfo.
  ///
  /// [replaceUniqueId] is the original uniqueId of a lazy queue item being
  /// resolved. When cross-source fallback changes the video identity,
  /// this lets [_addToQueue] find and replace the original item.
  Future<void> _playFromInfo(PlaybackInfo info, SearchVideoModel video,
      {int? gen, String? replaceUniqueId}) async {
    final bestAudio = info.bestAudio;
    if (bestAudio == null) throw Exception('No audio stream available');

    _manualStop = false;

    // Try audio streams with fallback through backup URLs
    String? playedUrl;
    String playedLabel = '';
    Map<String, String> playedHeaders = const {};
    for (final stream in info.audioStreams) {
      // 检查是否已被取消
      if (gen != null && gen != _playGeneration) return;
      try {
        await _playback.playAudioWithHeaders(stream.url, stream.headers);
        playedUrl = stream.url;
        playedLabel = stream.qualityLabel;
        playedHeaders = stream.headers;
        break;
      } catch (e) {
        log('Audio stream ${stream.qualityLabel} failed: $e');
        if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
          try {
            if (gen != null && gen != _playGeneration) return;
            await _playback.playAudioWithHeaders(
                stream.backupUrl!, stream.headers);
            playedUrl = stream.backupUrl!;
            playedLabel = stream.qualityLabel;
            playedHeaders = stream.headers;
            break;
          } catch (e2) {
            log('Audio stream ${stream.qualityLabel} backup failed: $e2');
          }
        }
      }
    }

    if (playedUrl == null) throw Exception('All audio streams failed');

    audioQualityLabel.value = playedLabel;

    _addToQueue(
      video: video,
      audioUrl: playedUrl,
      qualityLabel: playedLabel,
      headers: playedHeaders,
      replaceUniqueId: replaceUniqueId,
    );
  }

  void _addToQueue({
    required SearchVideoModel video,
    required String audioUrl,
    String qualityLabel = '',
    Map<String, String> headers = const {},
    String? replaceUniqueId,
  }) {
    final queueItem = QueueItem(
      video: video,
      audioUrl: audioUrl,
      qualityLabel: qualityLabel,
      headers: headers,
    );

    // Find existing item: first by resolved video uniqueId, then by original
    // uniqueId (for cross-source fallback where the identity changed).
    var existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex < 0 && replaceUniqueId != null) {
      existingIndex =
          queue.indexWhere((item) => item.video.uniqueId == replaceUniqueId);
    }

    // Only push to history if we're replacing a different song.
    // Skip when updating the current song in-place (e.g. lazy resolve).
    if (existingIndex != 0) {
      _pushToHistory();
    }

    if (existingIndex >= 0) {
      queue.removeAt(existingIndex);
    }
    queue.insert(0, queueItem);
    currentIndex.value = 0;
  }

  Future<void> _playQueueItem(QueueItem item, {int? gen}) async {
    await _playback.ensureMediaKit();

    // Lazy queue item: no URL pre-resolved, resolve now
    if (item.audioUrl.isEmpty) {
      await _resolveAndPlay(item, gen: gen);
      _manualStop = false;
      return;
    }

    try {
      await _playback.playAudioWithHeaders(item.audioUrl, item.headers);
      _manualStop = false;
    } catch (e) {
      log('Queue item playback failed, re-resolving: $e');
      await _resolveAndPlay(item, gen: gen);
      _manualStop = false;
    }
  }

  /// Resolve a queue item's playback URL and play it.
  Future<void> _resolveAndPlay(QueueItem item, {int? gen}) async {
    if (gen != null && gen != _playGeneration) return;
    final originalUniqueId = item.video.uniqueId;
    final resolved = await _registry.resolvePlaybackWithFallback(item.video);
    if (resolved == null) throw Exception('无法获取播放链接');
    final (info, resolvedVideo) = resolved;
    _putCachedResolve(originalUniqueId, info, resolvedVideo);

    final bestAudio = info.bestAudio;
    if (bestAudio == null) throw Exception('No audio stream available');

    String? playedUrl;
    String playedLabel = '';
    Map<String, String> playedHeaders = const {};
    for (final stream in info.audioStreams) {
      if (gen != null && gen != _playGeneration) return;
      try {
        await _playback.playAudioWithHeaders(stream.url, stream.headers);
        playedUrl = stream.url;
        playedLabel = stream.qualityLabel;
        playedHeaders = stream.headers;
        break;
      } catch (e) {
        log('Audio stream ${stream.qualityLabel} failed: $e');
        if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
          try {
            if (gen != null && gen != _playGeneration) return;
            await _playback.playAudioWithHeaders(
                stream.backupUrl!, stream.headers);
            playedUrl = stream.backupUrl!;
            playedLabel = stream.qualityLabel;
            playedHeaders = stream.headers;
            break;
          } catch (e2) {
            log('Audio stream ${stream.qualityLabel} backup failed: $e2');
          }
        }
      }
    }
    if (playedUrl == null) throw Exception('All audio streams failed');

    audioQualityLabel.value = playedLabel;
    currentPlaybackSourceId.value = info.sourceId;
    if (resolvedVideo.uniqueId != originalUniqueId) {
      currentVideo.value = resolvedVideo;
    }

    // Update queue[0] in-place instead of going through _addToQueue,
    // which can misidentify items and corrupt the queue.
    final resolvedItem = QueueItem(
      video: resolvedVideo,
      audioUrl: playedUrl,
      qualityLabel: playedLabel,
      headers: playedHeaders,
    );
    if (queue.isNotEmpty && queue[0].video.uniqueId == originalUniqueId) {
      queue[0] = resolvedItem;
    } else {
      // Fallback: find by originalUniqueId
      final idx =
          queue.indexWhere((q) => q.video.uniqueId == originalUniqueId);
      if (idx >= 0) {
        queue[idx] = resolvedItem;
      }
    }
  }

  void togglePlay() {
    if (!hasCurrentTrack) return;
    _playback.togglePlay();
  }

  void seekTo(Duration pos) => _playback.seekTo(pos);

  void _playNext() {
    if (_manualStop) {
      _manualStop = false;
      return;
    }
    _saveListenDuration();

    switch (playMode.value) {
      case PlayMode.repeatOne:
        _playback.seekTo(Duration.zero);
        _playback.play();
        break;
      case PlayMode.shuffle:
        if (queue.length <= 1) {
          _advanceNext().catchError((e) => log('Advance next error: $e'));
          return;
        }
        final rng = Random();
        final next = 1 + rng.nextInt(queue.length - 1);
        playAt(next);
        break;
      case PlayMode.sequential:
        _advanceNext().catchError((e) => log('Advance next error: $e'));
        break;
    }
  }

  Future<void> skipNext() async {
    _saveListenDuration();
    ++_playGeneration;
    await _advanceOrStop();
  }

  Future<void> _advanceNext() async {
    await _advanceOrStop();
  }

  Future<void> _advanceOrStop() async {
    log('_advanceOrStop: queue.length=${queue.length}');
    if (queue.length > 1) {
      _pushToHistory();
      queue.removeAt(0);
      currentIndex.value = 0;
      await _playCurrentQueueItem();
    } else {
      _manualStop = true;
      _pushToHistory();
      if (queue.isNotEmpty) queue.removeAt(0);
      currentIndex.value = -1;
      currentVideo.value = null;
      _playback.stop();
      AppToast.show('播放队列已播完');
    }
  }

  /// Play the current queue[0] item with error handling.
  ///
  /// When [userInitiated] is false (default, e.g. auto-advance), failed items
  /// are removed and the next item is tried. When true (e.g. user tapped a
  /// specific song), the failed item stays in the queue and an error is shown.
  Future<void> _playCurrentQueueItem({bool userInitiated = false}) async {
    final gen = _playGeneration;
    const maxSkips = 10;
    int skips = 0;
    while (queue.isNotEmpty && skips < maxSkips) {
      if (gen != _playGeneration) return;
      final item = queue[0];
      currentVideo.value = item.video;
      _updateUploaderMid(item.video);
      audioQualityLabel.value = item.qualityLabel;

      final needsResolve = item.audioUrl.isEmpty;
      if (needsResolve) isLoading.value = true;

      try {
        await _playQueueItem(item, gen: gen);
        if (gen != _playGeneration) return;
        if (needsResolve) isLoading.value = false;
        final played = queue.isNotEmpty ? queue[0] : item;
        _storage.addPlayHistory(played.video);
        _fetchLyrics(played.video);
        _loadRelatedMusic(played.video);
        return;
      } catch (e) {
        if (needsResolve) isLoading.value = false;
        if (gen != _playGeneration) return;
        log('Play queue item failed: $e');
        if (userInitiated) {
          AppToast.error('播放失败，请重试');
          return;
        }
        if (queue.isNotEmpty) queue.removeAt(0);
        skips++;
        if (queue.isNotEmpty) {
          AppToast.error('播放失败，跳到下一首');
          currentIndex.value = 0;
        }
      }
    }
    if (gen != _playGeneration) return;
    if (skips >= maxSkips) {
      AppToast.error('连续播放失败，已停止');
    } else {
      AppToast.show('播放队列已播完');
    }
    currentIndex.value = -1;
    currentVideo.value = null;
    _playback.stop();
  }

  Future<void> skipPrevious() async {
    _saveListenDuration();
    ++_playGeneration;
    // If played more than 3 seconds, restart current track
    if (currentVideo.value != null && position.value.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }
    // Go back to previous song from history
    if (playHistory.isNotEmpty) {
      _manualStop = true;
      final previous = playHistory.removeLast();
      // Current song goes back to the front of the queue
      queue.insert(0, previous);
      currentIndex.value = 0;
      await _playCurrentQueueItem();
    } else if (hasCurrentTrack) {
      // No history, just restart current track
      seekTo(Duration.zero);
    } else {
      // No track at all — do nothing instead of triggering random play
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

  void playAt(int index) {
    if (index <= 0 || index >= queue.length) return;
    if (index == 1) return;
    final item = queue.removeAt(index);
    queue.insert(1, item);
    AppToast.show('下一首播放: ${item.video.title}');
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex <= 0 || oldIndex >= queue.length) return;
    if (newIndex < 0 || newIndex > queue.length) return;
    if (newIndex == 0) newIndex = 1;
    if (oldIndex < newIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
  }

  void removeFromQueue(int index) {
    if (index == 0 || index < 0 || index >= queue.length) return;
    queue.removeAt(index);
  }

  void clearQueue() {
    ++_playGeneration;
    _saveListenDuration();
    _manualStop = true;
    _playback.stop();
    _playback.resetSwitchingTrack();
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
        final seen = <String>{normalizeTitle(video.title)};
        final deduped = results
            .where((s) => seen.add(normalizeTitle(s.title)))
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

  void refreshRelatedMusic() {
    final video = currentVideo.value;
    if (video != null) _loadRelatedMusic(video);
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
  @visibleForTesting
  static String normalizeTitle(String title) {
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
    final gen = ++_playGeneration;
    final video = song.toSearchVideoModel();

    _saveListenDuration();
    _manualStop = true;
    _playback.stop();

    isLoading.value = true;
    currentVideo.value = video;
    _updateUploaderMid(video);

    _navigateToPlayer();

    try {
      final audioUrl = await _musicRepo.getAudioUrl(song.id);
      if (gen != _playGeneration) return;

      if (audioUrl != null && audioUrl.isNotEmpty) {
        _manualStop = false;
        final headers = {
          'Referer': 'https://www.bilibili.com',
          'User-Agent': 'Mozilla/5.0',
        };
        try {
          final cookie = await HttpClient.instance
              .getCookieHeader(Uri.parse('https://api.bilibili.com'));
          if (cookie.isNotEmpty) headers['Cookie'] = cookie;
        } catch (_) {}
        await _playback.playAudioWithHeaders(audioUrl, headers);
        if (gen != _playGeneration) return;
        audioQualityLabel.value = 'AU';

        _addToQueue(
          video: video,
          audioUrl: audioUrl,
          qualityLabel: 'AU',
          headers: headers,
        );
      } else if (video.bvid.isNotEmpty) {
        // Fallback to normal Bilibili playback via adapter
        final resolved = await _registry.resolvePlaybackWithFallback(
          video,
          enableFallback: false,
        );
        if (gen != _playGeneration) return;
        if (resolved != null) {
          await _playFromInfo(resolved.$1, resolved.$2, gen: gen);
        } else {
          throw Exception('No playable URL');
        }
      } else {
        throw Exception('No playable URL');
      }
      if (gen != _playGeneration) return;
      _storage.addPlayHistory(video);
    } catch (e) {
      if (gen != _playGeneration) return;
      _manualStop = false;
      log('AU playback failed: $e');
      AppToast.error('播放失败: $e');
    }
    if (gen != _playGeneration) return;
    isLoading.value = false;
    _fetchLyrics(video);
    _loadRelatedMusic(video);
  }

  // ── Queue Resolution (shared by addToQueue and addToQueueSilent) ──

  Future<QueueItem?> _resolveQueueItem(SearchVideoModel video) async {
    // Check cache first
    var resolved = _getCachedResolve(video.uniqueId);
    if (resolved == null) {
      final fresh = await _registry.resolvePlaybackWithFallback(video);
      if (fresh == null) return null;
      _putCachedResolve(video.uniqueId, fresh.$1, fresh.$2);
      resolved = fresh;
    }

    final (info, resolvedVideo) = resolved;
    final bestAudio = info.bestAudio;
    if (bestAudio == null) return null;

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
      await _playCurrentQueueItem();
    }
  }

  /// Replace the entire queue and start playing from the first track.
  void playAllFromList(
    List<SearchVideoModel> tracks, {
    String? preferredSourceId,
  }) {
    if (tracks.isEmpty) return;
    _pushToHistory();
    queue.clear();
    currentIndex.value = -1;
    playFromSearch(tracks.first, preferredSourceId: preferredSourceId);
    for (int i = 1; i < tracks.length; i++) {
      addToQueueLazy(tracks[i]);
    }
  }

  /// Add a video to the queue without resolving URL (lazy resolution).
  /// URL will be resolved just-in-time when the song is about to play.
  /// This is instant and ideal for "Play All" scenarios.
  void addToQueueLazy(SearchVideoModel video) {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      log('addToQueueLazy: skipped duplicate "${video.title}" '
          '(uniqueId=${video.uniqueId})');
      return;
    }
    queue.add(QueueItem(video: video, audioUrl: ''));
    log('addToQueueLazy: added "${video.title}" (queue.length=${queue.length})');
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

  /// Add a video to play next (insert right after current track).
  Future<void> addToQueueNext(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.uniqueId == video.uniqueId);
    if (existingIndex >= 0) {
      // Move existing item to next position
      final item = queue.removeAt(existingIndex);
      queue.insert(queue.isEmpty ? 0 : 1, item);
      AppToast.show('将下一首播放');
      return;
    }

    try {
      final item = await _resolveQueueItem(video);
      if (item == null) return;
      queue.insert(queue.isEmpty ? 0 : 1, item);
      AppToast.show('将下一首播放');
      await _startPlaybackIfIdle();
    } catch (e) {
      log('Add to queue next failed: $e');
      AppToast.error('添加失败: $e');
    }
  }
}

/// Cached URL resolution result with TTL.
class _CachedResolve {
  final PlaybackInfo info;
  final SearchVideoModel resolvedVideo;
  final DateTime cachedAt;

  _CachedResolve(this.info, this.resolvedVideo) : cachedAt = DateTime.now();
}
