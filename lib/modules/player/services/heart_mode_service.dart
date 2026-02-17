import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/storage/storage_service.dart';
import '../../../data/models/search/search_video_model.dart';
import '../../../data/services/recommendation_service.dart';
import '../../../shared/utils/app_toast.dart';
import '../player_controller.dart';

/// Manages heart mode state and logic, decoupled from PlayerController.
class HeartModeService {
  final isHeartMode = false.obs;
  final heartModeTags = <String>[].obs;
  final isHeartModeLoading = false.obs;

  bool _pendingExit = false;
  List<QueueItem> _savedQueue = [];
  SearchVideoModel? _savedCurrentVideo;

  // Callbacks to PlayerController
  void Function(List<QueueItem> queue, int index, SearchVideoModel? video)?
      onRestoreQueue;
  Future<void> Function(SearchVideoModel video)? onPlayFromSearch;
  Future<bool> Function(SearchVideoModel video)? onAddToQueueSilent;
  void Function()? onStopPlayback;
  List<QueueItem> Function()? getCurrentQueue;
  SearchVideoModel? Function()? getCurrentVideo;

  bool get pendingExit => _pendingExit;

  /// Called when a track completes. Returns true if heart mode handled it.
  bool handleTrackCompleted() {
    if (!_pendingExit) return false;
    _pendingExit = false;
    _exitAndRestoreQueue();
    return true;
  }

  Future<void> activate(List<String> tags) async {
    // Save current state
    _savedQueue = List.from(getCurrentQueue?.call() ?? []);

    _savedCurrentVideo = getCurrentVideo?.call();

    isHeartMode.value = true;
    heartModeTags.assignAll(tags);
    isHeartModeLoading.value = true;

    try {
      final recService = Get.find<RecommendationService>();
      final songs = await recService.getRecommendations(tags: tags);

      if (songs.isEmpty) {
        AppToast.error('未找到推荐歌曲');
        _restore();
        return;
      }

      // PlayerController clears queue and plays songs
      await onPlayFromSearch?.call(songs.first);

      for (int i = 1; i < songs.length; i++) {
        await onAddToQueueSilent?.call(songs[i]);
      }

      AppToast.show('心动模式已开启');
    } catch (e) {
      log('activateHeartMode error: $e');
      AppToast.error('心动模式启动失败');
      _restore();
    } finally {
      isHeartModeLoading.value = false;
    }
  }

  void deactivate() {
    _pendingExit = true;
    AppToast.show('当前曲目播完后将退出心动模式');
  }

  void toggle() {
    if (isHeartMode.value) {
      deactivate();
    }
  }

  Future<void> autoNext() async {
    isHeartModeLoading.value = true;
    try {
      final recService = Get.find<RecommendationService>();
      final storage = Get.find<StorageService>();
      final currentQueue = getCurrentQueue?.call() ?? [];

      // Combine queue songs + storage play history for better dedup
      final recentPlayed = currentQueue
          .map((q) => '${q.video.title} - ${q.video.author}')
          .toList();
      final historyEntries = storage.getPlayHistory().take(30);
      for (final entry in historyEntries) {
        final v = entry['video'] as Map<String, dynamic>?;
        if (v != null) {
          final model = SearchVideoModel.fromJson(v);
          final desc = '${model.title} - ${model.author}';
          if (!recentPlayed.contains(desc)) {
            recentPlayed.add(desc);
          }
        }
      }

      final songs = await recService.getRecommendations(
        tags: heartModeTags.toList(),
        recentPlayed: recentPlayed,
      );

      final queueIds =
          currentQueue.map((q) => q.video.uniqueId).toSet();
      for (final song in songs) {
        if (!queueIds.contains(song.uniqueId)) {
          await onPlayFromSearch?.call(song);
          isHeartModeLoading.value = false;
          return;
        }
      }

      onStopPlayback?.call();
      AppToast.show('心动模式暂无更多推荐');
    } catch (e) {
      log('heartModeAutoNext error: $e');
      onStopPlayback?.call();
    } finally {
      isHeartModeLoading.value = false;
    }
  }

  void _exitAndRestoreQueue() {
    isHeartMode.value = false;
    heartModeTags.clear();

    onRestoreQueue?.call(_savedQueue, 0, _savedCurrentVideo);

    _savedQueue = [];

    _savedCurrentVideo = null;

    AppToast.show('已退出心动模式');
  }

  void _restore() {
    isHeartMode.value = false;
    heartModeTags.clear();
    _pendingExit = false;

    onRestoreQueue?.call(_savedQueue, 0, _savedCurrentVideo);

    _savedQueue = [];

    _savedCurrentVideo = null;
  }
}
