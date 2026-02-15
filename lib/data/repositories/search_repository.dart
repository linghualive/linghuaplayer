import 'dart:convert';

import 'package:get/get.dart';

import '../../core/crypto/wbi_sign.dart';
import '../../shared/utils/html_utils.dart';
import '../models/search/hot_search_model.dart';
import '../models/search/search_result_model.dart';
import '../models/search/search_suggest_model.dart';
import '../models/search/search_video_model.dart';
import '../providers/search_provider.dart';

class SearchRepository {
  final _provider = Get.find<SearchProvider>();

  /// Get hot search keywords
  Future<List<HotSearchModel>> getHotSearch() async {
    final res = await _provider.getHotSearch();
    dynamic resData = res.data;

    // Response may be JSON string or Map
    if (resData is String) {
      resData = json.decode(resData);
    }

    if (resData['code'] == 0) {
      final list = resData['list'] as List<dynamic>? ?? [];
      return list
          .map((e) => HotSearchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get search suggestions
  Future<List<SearchSuggestModel>> getSuggestions(String term) async {
    final res = await _provider.getSuggestions(term);
    dynamic resData = res.data;

    if (resData is String) {
      resData = json.decode(resData);
    }

    if (resData['code'] == 0 && resData['result'] is Map) {
      final tags = resData['result']['tag'] as List<dynamic>? ?? [];
      return tags
          .map((e) => SearchSuggestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Search videos by keyword with WBI signing
  Future<SearchResultModel?> searchVideos({
    required String keyword,
    required int page,
    String order = 'totalrank',
  }) async {
    final params = await WbiSign.makSign({
      'search_type': 'video',
      'keyword': keyword,
      'page': page,
      'order': order,
      'platform': 'web',
      'web_location': 333.999,
    });

    final res = await _provider.searchByType(params);
    // Check HTTP status first (412 from server-level risk control)
    if (res.statusCode == 412) {
      throw Exception('B站搜索触发风控，请稍后再试');
    }
    final code = res.data['code'];
    if (code == -412) {
      throw Exception('B站搜索触发风控，请稍后再试');
    }
    if (code == 0 && res.data['data'] != null) {
      final result = SearchResultModel.fromJson(
          res.data['data'] as Map<String, dynamic>);

      // Strip HTML from titles
      final cleanedResults = result.results.map((video) {
        return SearchVideoModel(
          id: video.id,
          author: video.author,
          mid: video.mid,
          title: HtmlUtils.stripHtmlTags(video.title),
          description: video.description,
          pic: video.pic,
          play: video.play,
          danmaku: video.danmaku,
          duration: video.duration,
          bvid: video.bvid,
          arcurl: video.arcurl,
        );
      }).toList();

      return SearchResultModel(
        page: result.page,
        pageSize: result.pageSize,
        numResults: result.numResults,
        numPages: result.numPages,
        results: cleanedResults,
      );
    }
    return null;
  }

  /// Get CID from BV id
  Future<int?> getCid(String bvid) async {
    final res = await _provider.getPagelist(bvid);
    if (res.data['code'] == 0) {
      final data = res.data['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        return data.first['cid'] as int?;
      }
    }
    return null;
  }
}
