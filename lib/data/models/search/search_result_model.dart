import 'search_video_model.dart';

class SearchResultModel {
  final int page;
  final int pageSize;
  final int numResults;
  final int numPages;
  final List<SearchVideoModel> results;

  SearchResultModel({
    required this.page,
    required this.pageSize,
    required this.numResults,
    required this.numPages,
    required this.results,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final resultList = json['result'] as List<dynamic>? ?? [];
    return SearchResultModel(
      page: json['page'] as int? ?? 1,
      pageSize: json['pagesize'] as int? ?? 20,
      numResults: json['numResults'] as int? ?? 0,
      numPages: json['numPages'] as int? ?? 0,
      results: resultList
          .map((e) => SearchVideoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => page < numPages;
}
