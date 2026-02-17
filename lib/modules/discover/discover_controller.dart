import 'dart:developer';

import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/deepseek_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/recommendation_service.dart';
import '../player/player_controller.dart';

class DiscoverController extends GetxController {
  final _storage = Get.find<StorageService>();
  final _userRepo = Get.find<UserRepository>();

  final preferenceTags = <String>[].obs;
  final isGeneratingTags = false.obs;
  final aiRecommendedSongs = <SearchVideoModel>[].obs;
  final isLoadingRecommendations = false.obs;
  final hasApiKey = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadState();
  }

  void _loadState() {
    hasApiKey.value = (_storage.deepseekApiKey ?? '').isNotEmpty;
    preferenceTags.assignAll(_storage.preferenceTags);
  }

  void refreshApiKeyState() {
    hasApiKey.value = (_storage.deepseekApiKey ?? '').isNotEmpty;
  }

  Future<void> generateTagsFromHistory() async {
    if (!hasApiKey.value) return;

    isGeneratingTags.value = true;
    try {
      final deepseekRepo = Get.find<DeepSeekRepository>();

      // Get recent 30 history items
      final history = await _userRepo.getHistoryCursor(ps: 30);
      if (history.items.isEmpty) {
        isGeneratingTags.value = false;
        return;
      }

      final descriptions = history.items
          .map((h) => '${h.title} - ${h.authorName}')
          .toList();

      final tags = await deepseekRepo.generatePreferenceTags(descriptions);
      preferenceTags.assignAll(tags);
      _storage.preferenceTags = tags;
    } catch (e) {
      log('generateTagsFromHistory error: $e');
    } finally {
      isGeneratingTags.value = false;
    }
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !preferenceTags.contains(tag)) {
      preferenceTags.add(tag);
      _storage.preferenceTags = preferenceTags.toList();
    }
  }

  void removeTag(String tag) {
    preferenceTags.remove(tag);
    _storage.preferenceTags = preferenceTags.toList();
  }

  void saveTagsToStorage(List<String> tags) {
    preferenceTags.assignAll(tags);
    _storage.preferenceTags = tags;
  }

  Future<void> loadRecommendations() async {
    if (!hasApiKey.value) return;

    isLoadingRecommendations.value = true;
    aiRecommendedSongs.clear();

    try {
      final recService = Get.find<RecommendationService>();
      final songs = await recService.getRecommendations(
        tags: preferenceTags.toList(),
      );
      aiRecommendedSongs.assignAll(songs);
    } catch (e) {
      log('loadRecommendations error: $e');
    } finally {
      isLoadingRecommendations.value = false;
    }
  }

  void enterHeartMode() {
    final playerCtrl = Get.find<PlayerController>();
    // Pass tags if available, empty list means random mode
    playerCtrl.activateHeartMode(preferenceTags.toList());
  }
}
