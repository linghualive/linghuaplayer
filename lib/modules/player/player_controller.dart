import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../app/constants/app_constants.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/player_repository.dart';

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

  // Audio quality
  final audioQualityLabel = ''.obs;
  final videoQualityLabel = ''.obs;

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
      if (!isVideoMode.value) position.value = pos;
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
      if (isVideoMode.value) position.value = pos;
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

  /// Play from search result
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

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
      await _audioPlayer.play();
    } catch (e) {
      log('Audio source error: $e');
      rethrow;
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
  }

  Future<void> skipNext() async {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      final item = queue[currentIndex.value];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;

      await _playQueueItem(item);
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
    } else {
      seekTo(Duration.zero);
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
  }

  bool get hasCurrentTrack => currentVideo.value != null;
}
