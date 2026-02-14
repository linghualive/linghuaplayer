import 'audio_stream_model.dart';
import 'video_stream_model.dart';

class PlayUrlModel {
  final List<AudioStreamModel> audioStreams;
  final List<VideoStreamModel> videoStreams;

  PlayUrlModel({required this.audioStreams, required this.videoStreams});

  factory PlayUrlModel.fromJson(Map<String, dynamic> json) {
    final dash = json['dash'] as Map<String, dynamic>?;
    if (dash == null) {
      return PlayUrlModel(audioStreams: [], videoStreams: []);
    }

    final List<AudioStreamModel> streams = [];

    // 1. Parse Hi-Res / FLAC audio (highest priority)
    // dash.flac.audio is a single object (not a list)
    final flac = dash['flac'];
    if (flac != null && flac is Map<String, dynamic>) {
      final flacAudio = flac['audio'];
      if (flacAudio != null && flacAudio is Map<String, dynamic>) {
        final flacStream = AudioStreamModel.fromJson(flacAudio);
        if (flacStream.baseUrl.isNotEmpty) {
          streams.add(flacStream);
        }
      }
    }

    // 2. Parse Dolby audio (second priority)
    // dash.dolby.audio is a list
    final dolby = dash['dolby'];
    if (dolby != null && dolby is Map<String, dynamic>) {
      final dolbyAudioList = dolby['audio'];
      if (dolbyAudioList != null && dolbyAudioList is List) {
        for (final item in dolbyAudioList) {
          if (item is Map<String, dynamic>) {
            final dolbyStream = AudioStreamModel.fromJson(item);
            if (dolbyStream.baseUrl.isNotEmpty) {
              streams.add(dolbyStream);
            }
          }
        }
      }
    }

    // 3. Parse standard audio streams (64K, 132K, 192K)
    final audioList = dash['audio'];
    if (audioList != null && audioList is List) {
      for (final item in audioList) {
        if (item is Map<String, dynamic>) {
          streams.add(AudioStreamModel.fromJson(item));
        }
      }
    }

    // Sort by quality priority descending, then bandwidth descending as tiebreaker
    streams.sort((a, b) {
      final priorityCompare =
          b.qualityPriority.compareTo(a.qualityPriority);
      if (priorityCompare != 0) return priorityCompare;
      return b.bandwidth.compareTo(a.bandwidth);
    });

    // 4. Parse video streams
    final List<VideoStreamModel> videoList = [];
    final dashVideo = dash['video'];
    if (dashVideo != null && dashVideo is List) {
      for (final item in dashVideo) {
        if (item is Map<String, dynamic>) {
          final vs = VideoStreamModel.fromJson(item);
          if (vs.baseUrl.isNotEmpty) {
            videoList.add(vs);
          }
        }
      }
    }

    // Sort video streams: highest quality first, prefer AVC at same quality
    videoList.sort((a, b) {
      final qualityCompare = b.id.compareTo(a.id);
      if (qualityCompare != 0) return qualityCompare;
      // At same quality, prefer AVC (codecid=7) for broadest hardware support
      if (a.isAvc && !b.isAvc) return -1;
      if (!a.isAvc && b.isAvc) return 1;
      return b.bandwidth.compareTo(a.bandwidth);
    });

    return PlayUrlModel(audioStreams: streams, videoStreams: videoList);
  }

  /// Get the best quality audio stream available
  AudioStreamModel? get bestAudio =>
      audioStreams.isNotEmpty ? audioStreams.first : null;

  /// Get the best quality video stream available (prefers AVC)
  VideoStreamModel? get bestVideo =>
      videoStreams.isNotEmpty ? videoStreams.first : null;

  /// Get all available audio quality labels
  List<String> get availableQualities =>
      audioStreams.map((s) => s.qualityLabel).toList();

  /// Get all available video quality labels
  List<String> get availableVideoQualities =>
      videoStreams.map((s) => '${s.qualityLabel} ${s.codecs}').toList();
}
