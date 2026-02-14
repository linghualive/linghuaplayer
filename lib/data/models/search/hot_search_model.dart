class HotSearchModel {
  final String keyword;
  final String showName;
  final String? icon;
  final int position;

  HotSearchModel({
    required this.keyword,
    required this.showName,
    this.icon,
    required this.position,
  });

  factory HotSearchModel.fromJson(Map<String, dynamic> json) {
    return HotSearchModel(
      keyword: json['keyword'] as String? ?? '',
      showName: json['show_name'] as String? ?? json['keyword'] as String? ?? '',
      icon: json['icon'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }
}
