class SearchSuggestModel {
  final String value;
  final String term;
  final String name;

  SearchSuggestModel({
    required this.value,
    required this.term,
    required this.name,
  });

  factory SearchSuggestModel.fromJson(Map<String, dynamic> json) {
    return SearchSuggestModel(
      value: json['value'] as String? ?? '',
      term: json['term'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
