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
import '../../data/models/player/lyrics_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/lyrics_repository.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/search_repository.dart';
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

  /// Play from search result and navigate to player page
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

    _navigateToPlayer();

    try {
      if (video.isNetease) {
        await _playNetease(video);
      } else if (_storage.enableVideo) {
        await _playWithVideo(video);
      } else {
        await _playAudioOnly(video);
      }
      _storage.addPlayHistory(video);
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
      '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
      '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
    ];
    final random = Random();
    final keyword = keywords[random.nextInt(keywords.length)];

    try {
      // Prefer NetEase search for pure music results
      final neteaseResult = await _neteaseRepo.searchSongs(
        keyword: keyword,
        limit: 10,
      );
      if (neteaseResult.songs.isNotEmpty) {
        final maxIndex = neteaseResult.songs.length.clamp(1, 5);
        final video = neteaseResult.songs[random.nextInt(maxIndex)];
        await playFromSearch(video);
        return;
      }

      // Fallback to Bilibili
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
    _playback.prepareForAudioOnly();

    final streams = await _playerRepo.getAudioStreams(video.bvid);
    if (streams.isEmpty) {
      AppToast.error('获取音频流失败');
      isLoading.value = false;
      return;
    }

    final result = await _playback.tryPlayStreams(streams);
    log('Playing with quality: ${result.qualityLabel}');
    audioQualityLabel.value = result.qualityLabel;
    videoQualityLabel.value = '';

    _addToQueue(
      video: video,
      audioUrl: result.url,
      qualityLabel: result.qualityLabel,
    );
  }

  Future<void> _playWithVideo(SearchVideoModel video) async {
    await _playback.prepareForVideo();

    final playUrl = await _playerRepo.getFullPlayUrl(video.bvid);
    if (playUrl == null || playUrl.videoStreams.isEmpty) {
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

    audioQualityLabel.value = bestAudio.qualityLabel;
    videoQualityLabel.value = bestVideo.qualityLabel;

    await _playback.playVideoWithAudio(bestVideo.baseUrl, bestAudio.baseUrl);

    _addToQueue(
      video: video,
      audioUrl: bestAudio.baseUrl,
      qualityLabel: bestAudio.qualityLabel,
      videoUrl: bestVideo.baseUrl,
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
      final item = queue.removeAt(existingIndex);
      queue.insert(0, item);
    } else {
      queue.insert(0, queueItem);
    }
    currentIndex.value = 0;
  }

  Future<void> _playQueueItem(QueueItem item) async {
    if (item.video.isNetease) {
      await _playback.ensureMediaKit();
      _playback.isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playback.playDirectAudio(item.audioUrl);
    } else if (item.videoUrl != null && _storage.enableVideo) {
      videoQualityLabel.value = item.videoQualityLabel ?? '';
      await _playback.playVideoWithAudio(item.videoUrl!, item.audioUrl);
    } else {
      await _playback.ensureMediaKit();
      _playback.isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playback.playBilibiliAudio(item.audioUrl);
    }
  }

  Future<void> _playNetease(SearchVideoModel video) async {
    _playback.prepareForAudioOnly();

    final url = await _neteaseRepo.getSongUrl(video.id);
    if (url != null && url.isNotEmpty) {
      await _playback.playDirectAudio(url);
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

  Future<void> _fallbackToBilibili(SearchVideoModel neteaseVideo) async {
    final keyword = '${neteaseVideo.title} ${neteaseVideo.author}'.trim();
    log('NetEase URL unavailable, falling back to Bilibili search');

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
      _playback.prepareForAudioOnly();
      videoQualityLabel.value = '';
      await _playback.playBilibiliAudio(item.audioUrl);
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

            audioQualityLabel.value = bestAudio.qualityLabel;
            videoQualityLabel.value = bestVideo.qualityLabel;
            await _playback.prepareForVideo();
            await _playback.playVideoWithAudio(
                bestVideo.baseUrl, bestAudio.baseUrl);
            if (currentPos > Duration.zero) {
              await Future.delayed(const Duration(milliseconds: 500));
              _playback.seekTo(currentPos);
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

  void togglePlay() => _playback.togglePlay();

  void seekTo(Duration pos) => _playback.seekTo(pos);

  void _playNext() {
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

    // 1. Try related music not already in queue
    final queueIds = queue.map((q) => q.video.uniqueId).toSet();
    final candidates = relatedMusic
        .where((s) => !queueIds.contains(s.uniqueId))
        .toList();

    if (candidates.isNotEmpty) {
      await playFromSearch(candidates.first);
      return;
    }

    // 2. Discover more songs
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

    // 3. Nothing left, stop
    _playback.stop();
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
  Future<void> skipNext() async {
    if (queue.length > 1) {
      queue.removeAt(0);
      currentIndex.value = 0;
      final item = queue[0];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
      _loadRelatedMusic(item.video);
    } else {
      queue.clear();
      currentVideo.value = null;
      _hasAutoPlayed = false;
      await playRandomIfNeeded();
    }
  }

  /// Auto-advance when track finishes: keep current song in queue.
  Future<void> _advanceNext() async {
    if (queue.length > 1) {
      final item = queue[1];
      queue.removeAt(1);
      queue.insert(0, item);
      currentIndex.value = 0;
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
    if (currentVideo.value != null && position.value.inSeconds > 3) {
      seekTo(Duration.zero);
    } else {
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
    _playback.stop();
    _playback.isVideoMode.value = false;
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
  Future<void> playFromAudioSong(AudioSongModel song) async {
    final video = song.toSearchVideoModel();
    isLoading.value = true;
    currentVideo.value = video;

    _navigateToPlayer();

    try {
      final musicRepo = Get.find<MusicRepository>();
      final audioUrl = await musicRepo.getAudioUrl(song.id);

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
        await _playAudioOnly(video);
      } else {
        throw Exception('No playable URL');
      }
      _storage.addPlayHistory(video);
    } catch (e) {
      log('AU playback failed: $e');
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

  // ── Queue Resolution (shared by addToQueue and addToQueueSilent) ──

  Future<QueueItem?> _resolveQueueItem(SearchVideoModel video) async {
    if (video.isNetease) {
      final url = await _neteaseRepo.getSongUrl(video.id);
      if (url != null && url.isNotEmpty) {
        return QueueItem(
          video: video,
          audioUrl: url,
          qualityLabel: '网易云',
        );
      }
      // Fallback to Bilibili
      final fallback = await _searchBilibiliFallback(video);
      if (fallback != null) return _resolveQueueItem(fallback);
      return null;
    }

    if (_storage.enableVideo) {
      final playUrl = await _playerRepo.getFullPlayUrl(video.bvid);
      if (playUrl != null &&
          playUrl.videoStreams.isNotEmpty &&
          playUrl.bestAudio != null) {
        final bestVideo = playUrl.bestVideo!;
        final bestAudio = playUrl.bestAudio!;
        return QueueItem(
          video: video,
          audioUrl: bestAudio.baseUrl,
          qualityLabel: bestAudio.qualityLabel,
          videoUrl: bestVideo.baseUrl,
          videoQualityLabel: bestVideo.qualityLabel,
        );
      }
    }

    // Audio-only fallback
    final streams = await _playerRepo.getAudioStreams(video.bvid);
    if (streams.isNotEmpty) {
      return QueueItem(
        video: video,
        audioUrl: streams.first.baseUrl,
        qualityLabel: streams.first.qualityLabel,
      );
    }
    return null;
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

      // Check if we had a Bilibili fallback (resolved video differs from input)
      if (video.isNetease && !item.video.isNetease) {
        log('NetEase URL unavailable, used Bilibili fallback');
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
