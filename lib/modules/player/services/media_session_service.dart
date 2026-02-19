import 'dart:io';

import 'package:audio_service/audio_service.dart';

class MediaSessionService extends BaseAudioHandler with SeekHandler {
  // Callbacks — set by PlayerController
  void Function()? onPlayCallback;
  void Function()? onPauseCallback;
  void Function()? onSkipNextCallback;
  void Function()? onSkipPreviousCallback;
  void Function()? onStopCallback;
  void Function(Duration position)? onSeekToCallback;

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> play() async {
    onPlayCallback?.call();
  }

  @override
  Future<void> pause() async {
    onPauseCallback?.call();
  }

  @override
  Future<void> skipToNext() async {
    onSkipNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipPreviousCallback?.call();
  }

  @override
  Future<void> stop() async {
    onStopCallback?.call();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    onSeekToCallback?.call(position);
  }

  void setMediaMetadata({
    required String title,
    required String artist,
    String? artUri,
    Duration? duration,
  }) {
    final item = MediaItem(
      id: '$title-$artist',
      title: title,
      artist: artist,
      artUri: artUri != null && artUri.isNotEmpty ? Uri.tryParse(artUri) : null,
      duration: duration,
    );
    mediaItem.add(item);
  }

  void updatePlaybackState({
    required bool playing,
    required Duration position,
    Duration? bufferedPosition,
  }) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: position,
      bufferedPosition: bufferedPosition ?? Duration.zero,
    ));
  }

  void setIdle() {
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    mediaItem.add(null);
  }
}
