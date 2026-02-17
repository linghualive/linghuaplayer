/// A single playable stream with URL, quality metadata, and HTTP headers.
class StreamOption {
  final String url;
  final String? backupUrl;
  final String qualityLabel;
  final int bandwidth;
  final String codec;
  final Map<String, String> headers;

  const StreamOption({
    required this.url,
    this.backupUrl,
    this.qualityLabel = '',
    this.bandwidth = 0,
    this.codec = '',
    this.headers = const {},
  });
}

/// Resolved playback information for a track.
///
/// Contains ordered lists of audio and video streams.
/// The source adapter is responsible for populating [StreamOption.headers]
/// so that the playback layer does not need to know about source-specific
/// Referer / User-Agent requirements.
class PlaybackInfo {
  final List<StreamOption> audioStreams;
  final List<StreamOption> videoStreams;
  final String sourceId;

  const PlaybackInfo({
    required this.audioStreams,
    this.videoStreams = const [],
    required this.sourceId,
  });

  bool get hasVideo => videoStreams.isNotEmpty;

  StreamOption? get bestAudio =>
      audioStreams.isNotEmpty ? audioStreams.first : null;

  StreamOption? get bestVideo =>
      videoStreams.isNotEmpty ? videoStreams.first : null;
}
