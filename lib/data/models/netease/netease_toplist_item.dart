class NeteaseToplistItem {
  final int id;
  final String name;
  final String coverUrl;
  final String updateFrequency;
  final List<String> trackPreviews;

  NeteaseToplistItem({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.updateFrequency,
    required this.trackPreviews,
  });
}
