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
import '../../data/sources/music_source_adapter.dart';
import '../../data/sources/music_source_registry.dart';
import '../../shared/utils/app_toast.dart';
import 'services/heart_mode_service.dart';
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
  }

  @override
  void onClose() {
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

  /// Play from search result and navigate to player page
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

    _navigateToPlayer();

    try {
      final resolved = await _registry.resolvePlaybackWithFallback(
        video,
        videoMode: _storage.enableVideo,
      );

      if (resolved == null) {
        throw Exception('无法获取播放链接');
      }

      final (info, resolvedVideo) = resolved;

      // If fallback occurred, update the current video
      if (resolvedVideo.uniqueId != video.uniqueId) {
        currentVideo.value = resolvedVideo;
      }

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

    // 2. Fallback to random keyword search via registry sources
    const keywords = [
      '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
      '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    ];
    final random = Random();
    final keyword = keywords[random.nextInt(keywords.length)];

    try {
      for (final source in _registry.availableSources) {
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

    // Exclude both queue and recently played history to avoid ping-ponging
    final excludeIds = <String>{
      ...queue.map((q) => q.video.uniqueId),
      ...playHistory.map((q) => q.video.uniqueId),
      video.uniqueId,
    };

    // 1. Try related music not already played
    final candidates = relatedMusic
        .where((s) => !excludeIds.contains(s.uniqueId))
        .toList();

    if (candidates.isNotEmpty) {
      AppToast.show('已为你自动推荐');
      await playFromSearch(candidates.first);
      return;
    }

    // 2. Discover more songs via source adapter
    try {
      final source = _registry.getSourceForTrack(video);
      if (source != null) {
        final moreSongs = await source.getRelatedTracks(video);
        final filtered = moreSongs
            .where((s) => !excludeIds.contains(s.uniqueId))
            .toList();
        if (filtered.isNotEmpty) {
          AppToast.show('已为你自动推荐');
          await playFromSearch(filtered.first);
          return;
        }
      }
    } catch (e) {
      log('Auto-play discover error: $e');
    }

    // 3. Nothing left, stop
    _manualStop = true;
    _playback.stop();
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
      _playQueueItem(item);
    } else {
      currentVideo.value = video;
      _playback.stop();
    }
  }

  /// User manually skips: remove current song from queue, then play next.
  /// If queue is empty, just stop — don't auto-recommend.
  Future<void> skipNext() async {
    if (queue.length > 1) {
      _pushToHistory();
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
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
    if (queue.length > 1) {
      _pushToHistory();
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
      _loadRelatedMusic(item.video);
    } else {
      _autoPlayNext();
    }
  }

  Future<void> skipPrevious() async {
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
    _manualStop = true;
    _playback.stop();
    _playback.isVideoMode.value = false;
    queue.clear();
    playHistory.clear();
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

  /// Load uploader's seasons/series (合集) — Bilibili-specific
  Future<MemberSeasonsResult> loadUploaderSeasons() async {
    final video = currentVideo.value;
    if (video == null || video.isBilibili == false || video.mid <= 0) {
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }

    try {
      return await _musicRepo.getMemberSeasons(video.mid);
    } catch (e) {
      log('Uploader seasons fetch error: $e');
      return MemberSeasonsResult(seasons: [], hasMore: false);
    }
  }

  /// Load one page of videos in a collection (合集 or 系列) — Bilibili-specific
  Future<CollectionPage> loadCollectionPage(
      MemberSeason season, {int pn = 1}) async {
    final video = currentVideo.value;
    if (video == null || video.isBilibili == false || video.mid <= 0) {
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
