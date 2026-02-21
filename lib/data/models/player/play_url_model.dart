import 'audio_stream_model.dart';

class PlayUrlModel {
  final List<AudioStreamModel> audioStreams;

  PlayUrlModel({required this.audioStreams});

  factory PlayUrlModel.fromJson(Map<String, dynamic> json) {
    final dash = json['dash'] as Map<String, dynamic>?;
    if (dash == null) {
      return PlayUrlModel(audioStreams: []);
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

    return PlayUrlModel(audioStreams: streams);
  }

  /// Get the best quality audio stream available
  AudioStreamModel? get bestAudio =>
      audioStreams.isNotEmpty ? audioStreams.first : null;

  /// Get all available audio quality labels
  List<String> get availableQualities =>
      audioStreams.map((s) => s.qualityLabel).toList();
}
