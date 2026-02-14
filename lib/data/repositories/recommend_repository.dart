import 'package:get/get.dart';

import '../models/recommend/rec_video_item_model.dart';
import '../providers/recommend_provider.dart';

class RecommendRepository {
  final _provider = Get.find<RecommendProvider>();

  Future<List<RecVideoItemModel>> getTopFeedRcmd({
    required int freshIdx,
    int brush = 1,
  }) async {
    final res = await _provider.getTopFeedRcmd(
      freshIdx: freshIdx,
      brush: brush,
    );

    if (res.data['code'] == 0 && res.data['data'] != null) {
      final items = res.data['data']['item'] as List<dynamic>? ?? [];
      return items
          .map((e) => RecVideoItemModel.fromJson(e as Map<String, dynamic>))
          .where((item) => item.goto == 'av')
          .toList();
    }
    return [];
  }
}
