import 'dart:developer';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/constants/app_constants.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/player_repository.dart';

class QueueItem {
  final SearchVideoModel video;
  final String audioUrl;
  final String qualityLabel;

  QueueItem({
    required this.video,
    required this.audioUrl,
    this.qualityLabel = '',
  });
}

class PlayerController extends GetxController {
  final _playerRepo = Get.find<PlayerRepository>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Reactive state
  final currentVideo = Rxn<SearchVideoModel>();
  final isPlaying = false.obs;
  final isLoading = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final buffered = Duration.zero.obs;

  // Queue
  final queue = <QueueItem>[].obs;
  final currentIndex = (-1).obs;

  // Audio quality
  final audioQualityLabel = ''.obs;

  AudioPlayer get audioPlayer => _audioPlayer;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) duration.value = dur;
    });

    _audioPlayer.bufferedPositionStream.listen((buf) {
      buffered.value = buf;
    });
  }

  /// Play from search result
  Future<void> playFromSearch(SearchVideoModel video) async {
    isLoading.value = true;
    currentVideo.value = video;

    try {
      // Get all audio streams sorted by quality (highest first)
      final streams = await _playerRepo.getAudioStreams(video.bvid);
      if (streams.isEmpty) {
        Get.snackbar('Error', 'Failed to get audio stream',
            snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        return;
      }

      // Try each quality tier from highest to lowest until one works
      String? playedUrl;
      String playedQuality = '';
      for (final stream in streams) {
        log('Trying ${stream.qualityLabel} (id=${stream.id}, '
            'codecs=${stream.codecs}, bandwidth=${stream.bandwidth})');
        try {
          await _playUrl(stream.baseUrl);
          playedUrl = stream.baseUrl;
          playedQuality = stream.qualityLabel;
          break;
        } catch (e) {
          log('${stream.qualityLabel} baseUrl failed: $e');
          // Try backup URL for this quality
          if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
            try {
              await _playUrl(stream.backupUrl!);
              playedUrl = stream.backupUrl!;
              playedQuality = stream.qualityLabel;
              break;
            } catch (e2) {
              log('${stream.qualityLabel} backupUrl failed: $e2');
            }
          }
          // Continue to next lower quality
        }
      }

      if (playedUrl == null) {
        throw Exception('All audio quality tiers failed');
      }

      log('Playing with quality: $playedQuality');
      audioQualityLabel.value = playedQuality;

      final queueItem = QueueItem(
        video: video,
        audioUrl: playedUrl,
        qualityLabel: playedQuality,
      );

      // Add to queue if not already there
      final existingIndex =
          queue.indexWhere((item) => item.video.bvid == video.bvid);
      if (existingIndex >= 0) {
        currentIndex.value = existingIndex;
      } else {
        queue.add(queueItem);
        currentIndex.value = queue.length - 1;
      }
    } catch (e) {
      log('Playback failed: $e');
      Get.snackbar('Error', 'Playback failed: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
    isLoading.value = false;
  }

  Future<void> _playUrl(String url) async {
    // Bilibili CDN requires Referer and User-Agent headers
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
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  void _playNext() {
    if (currentIndex.value < queue.length - 1) {
      skipNext();
    } else {
      _audioPlayer.stop();
      _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> skipNext() async {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      final item = queue[currentIndex.value];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;
      await _playUrl(item.audioUrl);
    }
  }

  Future<void> skipPrevious() async {
    // If past 3 seconds, restart current; else go to previous
    if (position.value.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
    } else if (currentIndex.value > 0) {
      currentIndex.value--;
      final item = queue[currentIndex.value];
      currentVideo.value = item.video;
      audioQualityLabel.value = item.qualityLabel;
      await _playUrl(item.audioUrl);
    } else {
      _audioPlayer.seek(Duration.zero);
    }
  }

  void removeFromQueue(int index) {
    if (index == currentIndex.value) return;
    queue.removeAt(index);
    if (index < currentIndex.value) {
      currentIndex.value--;
    }
  }

  void clearQueue() {
    _audioPlayer.stop();
    queue.clear();
    currentIndex.value = -1;
    currentVideo.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  bool get hasCurrentTrack => currentVideo.value != null;
}
