import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../../app/constants/app_constants.dart';
import '../../../data/models/player/audio_stream_model.dart';

/// Whether the current platform requires media_kit for audio playback
/// (just_audio is unsupported on macOS/Linux).
bool get _useMediaKit => Platform.isMacOS || Platform.isLinux;

/// Encapsulates all platform-specific audio/video playback logic.
///
/// Owns both player instances (just_audio + media_kit) and consolidates
/// all `Platform.isMacOS || Platform.isLinux` checks into one place.
class PlaybackService {
  final AudioPlayer audioPlayer = AudioPlayer();

  mk.Player? _mediaKitPlayer;
  mkv.VideoController? _videoController;

  // Guard flag: true while opening new media to suppress spurious completed events
  bool _isSwitchingTrack = false;

  // Reactive state
  final isPlaying = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final buffered = Duration.zero.obs;
  final isVideoMode = false.obs;

  // Callbacks
  void Function()? onTrackCompleted;
  void Function(Duration pos)? onPositionUpdate;

  mkv.VideoController? get videoController => _videoController;

  /// Expose the mpv NativePlayer for AudioOutputService (desktop only).
  mk.NativePlayer? get nativePlayerRef =>
      _mediaKitPlayer?.platform as mk.NativePlayer?;

  static final _httpHeaders = {
    'user-agent': AppConstants.pcUserAgent,
    'referer': AppConstants.referer,
  };

  PlaybackService() {
    _setupAudioListeners();
  }

  void dispose() {
    audioPlayer.dispose();
    _mediaKitPlayer?.dispose();
  }

  // ── Listener Setup ──

  void _setupAudioListeners() {
    audioPlayer.playerStateStream.listen((state) {
      if (!isVideoMode.value && !_useMediaKit) {
        isPlaying.value = state.playing;
      }
      if (state.processingState == ProcessingState.completed) {
        if (!isVideoMode.value && !_useMediaKit) {
          onTrackCompleted?.call();
        }
      }
    });

    audioPlayer.positionStream.listen((pos) {
      if (!isVideoMode.value && !_useMediaKit) {
        position.value = pos;
        onPositionUpdate?.call(pos);
      }
    });

    audioPlayer.durationStream.listen((dur) {
      if (!isVideoMode.value && !_useMediaKit && dur != null) {
        duration.value = dur;
      }
    });

    audioPlayer.bufferedPositionStream.listen((buf) {
      if (!isVideoMode.value && !_useMediaKit) buffered.value = buf;
    });
  }

  Future<void> _ensureMediaKitPlayer() async {
    if (_mediaKitPlayer != null) return;

    _mediaKitPlayer = mk.Player(
      configuration: const mk.PlayerConfiguration(
        bufferSize: 5 * 1024 * 1024,
      ),
    );

    final nativePlayer = _mediaKitPlayer!.platform as mk.NativePlayer;
    await nativePlayer.setProperty('referrer', AppConstants.referer);
    await nativePlayer.setProperty('user-agent', AppConstants.pcUserAgent);

    _mediaKitPlayer!.stream.playing.listen((playing) {
      if (isVideoMode.value || _useMediaKit) {
        isPlaying.value = playing;
      }
    });

    _mediaKitPlayer!.stream.position.listen((pos) {
      if (isVideoMode.value || _useMediaKit) {
        position.value = pos;
        onPositionUpdate?.call(pos);
      }
    });

    _mediaKitPlayer!.stream.duration.listen((dur) {
      if (isVideoMode.value || _useMediaKit) {
        duration.value = dur;
      }
    });

    _mediaKitPlayer!.stream.buffer.listen((buf) {
      if (isVideoMode.value || _useMediaKit) {
        buffered.value = buf;
      }
    });

    _mediaKitPlayer!.stream.completed.listen((completed) {
      if (completed &&
          !_isSwitchingTrack &&
          (isVideoMode.value || _useMediaKit)) {
        onTrackCompleted?.call();
      }
    });
  }

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

  // ── Public Playback Controls ──

  void togglePlay() {
    if ((isVideoMode.value || _useMediaKit) && _mediaKitPlayer != null) {
      _mediaKitPlayer!.playOrPause();
    } else {
      if (audioPlayer.playing) {
        audioPlayer.pause();
      } else {
        audioPlayer.play();
      }
    }
  }

  void seekTo(Duration pos) {
    if ((isVideoMode.value || _useMediaKit) && _mediaKitPlayer != null) {
      _mediaKitPlayer!.seek(pos);
    } else {
      audioPlayer.seek(pos);
    }
  }

  void stop() {
    if (isVideoMode.value || _useMediaKit) {
      _mediaKitPlayer?.stop();
    } else {
      audioPlayer.stop();
      audioPlayer.seek(Duration.zero);
    }
  }

  void play() {
    if (isVideoMode.value || _useMediaKit) {
      _mediaKitPlayer?.play();
    } else {
      audioPlayer.play();
    }
  }

  // ── Audio Playback (with Bilibili headers) ──

  /// Play a Bilibili audio URL with referer/UA headers.
  /// Automatically uses media_kit on macOS/Linux.
  Future<void> playBilibiliAudio(String url) async {
    if (_useMediaKit) {
      await _playAudioWithMediaKit(url);
      return;
    }

    log('Playing audio URL: $url');
    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: {
            'Referer': AppConstants.referer,
            'User-Agent': AppConstants.pcUserAgent,
          },
        ),
      );
      audioPlayer.play();
    } catch (e) {
      log('Audio source error: $e');
      rethrow;
    }
  }

  /// Play a direct audio URL (no special headers, e.g. NetEase).
  /// Automatically uses media_kit on macOS/Linux.
  Future<void> playDirectAudio(String url) async {
    if (_useMediaKit) {
      await _playAudioWithMediaKit(url);
      return;
    }

    log('Playing direct audio URL: $url');
    try {
      await audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
      );
      audioPlayer.play();
    } catch (e) {
      log('Direct audio source error: $e');
      rethrow;
    }
  }

  /// Play an audio URL with source-provided HTTP headers.
  ///
  /// If [headers] is empty, plays without special headers (like NetEase).
  /// If [headers] contains Referer/UA, uses them (like Bilibili).
  Future<void> playAudioWithHeaders(
      String url, Map<String, String> headers) async {
    if (headers.isEmpty) {
      await playDirectAudio(url);
    } else {
      await playBilibiliAudio(url);
    }
  }

  Future<void> _playAudioWithMediaKit(String url) async {
    log('Playing audio with media_kit: $url');
    _isSwitchingTrack = true;
    try {
      audioPlayer.stop();
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

  // ── Video Playback ──

  /// Open video with separate audio stream (DASH).
  Future<void> playVideoWithAudio(String videoUrl, String audioUrl) async {
    await _ensureVideoController();
    isVideoMode.value = true;

    _isSwitchingTrack = true;
    try {
      final nativePlayer = _mediaKitPlayer!.platform as mk.NativePlayer;
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

  // ── Stream Retry Logic (consolidated) ──

  /// Try playing audio from a list of streams, trying baseUrl then backupUrl
  /// for each quality tier. Returns the URL and quality label that succeeded,
  /// or throws if all fail.
  ///
  /// [streams] comes from `PlayerRepository.getAudioStreams()`.
  Future<({String url, String qualityLabel})> tryPlayStreams(
    List<AudioStreamModel> streams,
  ) async {
    for (final stream in streams) {
      log('Trying ${stream.qualityLabel} (id=${stream.id}, '
          'codecs=${stream.codecs}, bandwidth=${stream.bandwidth})');
      try {
        await playBilibiliAudio(stream.baseUrl);
        return (url: stream.baseUrl, qualityLabel: stream.qualityLabel);
      } catch (e) {
        log('${stream.qualityLabel} baseUrl failed: $e');
        if (stream.backupUrl != null && stream.backupUrl!.isNotEmpty) {
          try {
            await playBilibiliAudio(stream.backupUrl!);
            return (url: stream.backupUrl!, qualityLabel: stream.qualityLabel);
          } catch (e2) {
            log('${stream.qualityLabel} backupUrl failed: $e2');
          }
        }
      }
    }
    throw Exception('All audio quality tiers failed');
  }

  // ── Mode Switching ──

  /// Prepare for audio-only mode: stop media_kit video if active.
  void prepareForAudioOnly() {
    if (isVideoMode.value) {
      _mediaKitPlayer?.stop();
    }
    isVideoMode.value = false;
  }

  /// Prepare for video mode: stop current audio playback.
  Future<void> prepareForVideo() async {
    if (!isVideoMode.value) {
      audioPlayer.stop();
      // On desktop, audio plays via media_kit – stop it before switching to video
      if (_useMediaKit && _mediaKitPlayer != null) {
        await _mediaKitPlayer!.stop();
      }
    }
    await _ensureVideoController();
  }

  /// Ensure media_kit is available (needed for queue item playback on macOS/Linux).
  Future<void> ensureMediaKit() async {
    await _ensureMediaKitPlayer();
  }
}
