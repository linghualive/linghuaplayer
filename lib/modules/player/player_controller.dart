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
import '../../data/models/music/audio_song_model.dart';
import '../../data/models/player/lyrics_model.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/lyrics_repository.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/player_repository.dart';

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
  final _lyricsRepo = Get.find<LyricsRepository>();
  final _storage = Get.find<StorageService>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // media_kit player (lazy init, only created when video mode is first used)
  mk.Player? _mediaKitPlayer;
  mkv.VideoController? _videoController;

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

  // Lyrics
  final lyrics = Rxn<LyricsData>();
  final currentLyricsIndex = (-1).obs;
  final showLyrics = false.obs;
  final lyricsLoading = false.obs;

  AudioPlayer get audioPlayer => _audioPlayer;
  mkv.VideoController? get videoController => _videoController;

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

  void _ensureMediaKitPlayer() {
    if (_mediaKitPlayer != null) return;

    _mediaKitPlayer = mk.Player(
      configuration: const mk.PlayerConfiguration(
        bufferSize: 5 * 1024 * 1024,
      ),
    );
    _videoController = mkv.VideoController(
      _mediaKitPlayer!,
      configuration: const mkv.VideoControllerConfiguration(
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );

    // Listen to media_kit player streams
    _mediaKitPlayer!.stream.playing.listen((playing) {
      if (isVideoMode.value) isPlaying.value = playing;
    });

    _mediaKitPlayer!.stream.position.listen((pos) {
      if (isVideoMode.value) {
        position.value = pos;
        _updateLyricsIndex(pos);
      }
    });

    _mediaKitPlayer!.stream.duration.listen((dur) {
      if (isVideoMode.value) duration.value = dur;
    });

    _mediaKitPlayer!.stream.buffer.listen((buf) {
      if (isVideoMode.value) buffered.value = buf;
    });

    _mediaKitPlayer!.stream.completed.listen((completed) {
      if (completed && isVideoMode.value) _playNext();
    });
  }

  /// Play from search result and navigate to player page
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

    // Navigate to player page if not already there
    if (Get.currentRoute != AppRoutes.player) {
      Get.toNamed(AppRoutes.player);
    }

    try {
      if (_storage.enableVideo) {
        await _playWithVideo(video);
      } else {
        await _playAudioOnly(video);
      }
    } catch (e) {
      log('Playback failed: $e');
      Get.snackbar('错误', '播放失败: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
    _fetchLyrics(video);
  }

  Future<void> _playAudioOnly(SearchVideoModel video) async {
    // Stop media_kit if it was playing
    if (isVideoMode.value) {
      _mediaKitPlayer?.stop();
    }
    isVideoMode.value = false;

    final streams = await _playerRepo.getAudioStreams(video.bvid);
    if (streams.isEmpty) {
      Get.snackbar('错误', '获取音频流失败',
          snackPosition: SnackPosition.BOTTOM);
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

    _ensureMediaKitPlayer();

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
        queue.indexWhere((item) => item.video.bvid == video.bvid);
    if (existingIndex >= 0) {
      currentIndex.value = existingIndex;
    } else {
      queue.add(queueItem);
      currentIndex.value = queue.length - 1;
    }
  }

  Future<void> _playQueueItem(QueueItem item) async {
    if (item.videoUrl != null && _storage.enableVideo) {
      _ensureMediaKitPlayer();
      isVideoMode.value = true;
      videoQualityLabel.value = item.videoQualityLabel ?? '';
      await _openVideoWithAudio(item.videoUrl!, item.audioUrl);
    } else {
      isVideoMode.value = false;
      videoQualityLabel.value = '';
      await _playAudioUrl(item.audioUrl);
    }
  }

  Future<void> _openVideoWithAudio(String videoUrl, String audioUrl) async {
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
  }

  Future<void> _playAudioUrl(String url) async {
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

  /// Switch the current track between video and audio-only mode.
  Future<void> toggleVideoMode() async {
    if (currentIndex.value < 0 || currentIndex.value >= queue.length) return;
    final item = queue[currentIndex.value];
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
        _ensureMediaKitPlayer();
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
            _ensureMediaKitPlayer();
            isVideoMode.value = true;
            audioQualityLabel.value = bestAudio.qualityLabel;
            videoQualityLabel.value = bestVideo.qualityLabel;
            await _openVideoWithAudio(bestVideo.baseUrl, bestAudio.baseUrl);
            if (currentPos > Duration.zero) {
              await Future.delayed(const Duration(milliseconds: 500));
              _mediaKitPlayer?.seek(currentPos);
            }
          } else {
            Get.snackbar('提示', '该视频无画面资源',
                snackPosition: SnackPosition.BOTTOM);
          }
        } catch (e) {
          log('Failed to fetch video: $e');
          Get.snackbar('错误', '获取视频失败',
              snackPosition: SnackPosition.BOTTOM);
        }
      }
    }
  }

  void togglePlay() {
    if (isVideoMode.value && _mediaKitPlayer != null) {
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
    if (isVideoMode.value && _mediaKitPlayer != null) {
      _mediaKitPlayer!.seek(pos);
    } else {
      _audioPlayer.seek(pos);
    }
  }

  void _playNext() {
    switch (playMode.value) {
      case PlayMode.repeatOne:
        seekTo(Duration.zero);
        if (isVideoMode.value) {
          _mediaKitPlayer?.play();
        } else {
          _audioPlayer.play();
        }
        break;
      case PlayMode.shuffle:
        if (queue.length <= 1) return;
        final rng = Random();
        int next;
        do {
          next = rng.nextInt(queue.length);
        } while (next == currentIndex.value);
        playAt(next);
        break;
      case PlayMode.sequential:
        if (currentIndex.value < queue.length - 1) {
          skipNext();
        } else {
          if (isVideoMode.value) {
            _mediaKitPlayer?.stop();
          } else {
            _audioPlayer.stop();
            _audioPlayer.seek(Duration.zero);
          }
        }
        break;
    }
  }

  Future<void> skipNext() async {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      final item = queue[currentIndex.value];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
    }
  }

  Future<void> skipPrevious() async {
    if (position.value.inSeconds > 3) {
      seekTo(Duration.zero);
    } else if (currentIndex.value > 0) {
      currentIndex.value--;
      final item = queue[currentIndex.value];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
      _fetchLyrics(item.video);
    } else {
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
    currentIndex.value = index;
    final item = queue[index];
    currentVideo.value = item.video;
    audioQualityLabel.value = item.qualityLabel;
    await _playQueueItem(item);
    _fetchLyrics(item.video);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);

    // Keep currentIndex pointing to the same item
    if (currentIndex.value == oldIndex) {
      currentIndex.value = newIndex;
    } else if (oldIndex < currentIndex.value &&
        newIndex >= currentIndex.value) {
      currentIndex.value--;
    } else if (oldIndex > currentIndex.value &&
        newIndex <= currentIndex.value) {
      currentIndex.value++;
    }
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
    if (index == currentIndex.value) return;
    queue.removeAt(index);
    if (index < currentIndex.value) {
      currentIndex.value--;
    }
  }

  void clearQueue() {
    if (isVideoMode.value) {
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
  }

  // -- Lyrics --

  void _fetchLyrics(SearchVideoModel video) {
    lyrics.value = null;
    currentLyricsIndex.value = -1;
    lyricsLoading.value = true;

    _lyricsRepo
        .getLyrics(video.title, video.author, video.duration, bvid: video.bvid)
        .then((result) {
      if (currentVideo.value?.bvid == video.bvid) {
        lyrics.value = result;
        lyricsLoading.value = false;
      }
    }).catchError((e) {
      log('Lyrics fetch error: $e');
      if (currentVideo.value?.bvid == video.bvid) {
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

    if (Get.currentRoute != AppRoutes.player) {
      Get.toNamed(AppRoutes.player);
    }

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
          Get.snackbar('错误', '播放失败: $e2',
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar('错误', '播放失败: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
    isLoading.value = false;
    _fetchLyrics(video);
  }

  /// Add a video to the queue silently (no snackbar).
  /// Returns true if added successfully, false if already in queue or failed.
  Future<bool> addToQueueSilent(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.bvid == video.bvid);
    if (existingIndex >= 0) return false;

    try {
      if (_storage.enableVideo) {
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
      Get.snackbar('提示', '已添加 $added 首到播放列表',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('提示', '所有歌曲已在播放列表中',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Add a video to the queue without navigating to the player page.
  /// If nothing is currently playing, starts playback.
  Future<void> addToQueue(SearchVideoModel video) async {
    final existingIndex =
        queue.indexWhere((item) => item.video.bvid == video.bvid);
    if (existingIndex >= 0) {
      Get.snackbar('提示', '已在播放列表中',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (_storage.enableVideo) {
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

      Get.snackbar('提示', '已添加到播放列表',
          snackPosition: SnackPosition.BOTTOM);

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
      Get.snackbar('错误', '添加失败: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
