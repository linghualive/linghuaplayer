import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/user/fav_folder_model.dart';
import '../../data/models/user/fav_resource_model.dart';
import '../../data/repositories/user_repository.dart';
import '../player/player_controller.dart';

class PlaylistController extends GetxController {
  final _repo = Get.find<UserRepository>();
  final _storage = Get.find<StorageService>();

  final folders = <FavFolderModel>[].obs;
  final visibleFolders = <FavFolderModel>[].obs;
  final isLoading = true.obs;

  // Per-folder video state
  final tabVideos = <int, List<FavResourceModel>>{}.obs;
  final tabHasMore = <int, bool>{}.obs;
  final tabPage = <int, int>{}.obs;
  final tabLoading = <int, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    final mid = int.tryParse(_storage.userMid ?? '') ?? 0;
    if (mid == 0) {
      isLoading.value = false;
      return;
    }
    try {
      final list = await _repo.getFavFolders(upMid: mid);
      folders.assignAll(list);
      _applyVisibleConfig();
    } catch (_) {
      // Prevent stuck loading on network/parse errors
    }
    isLoading.value = false;
  }

  void _applyVisibleConfig() {
    final configured = _storage.playlistVisibleFolderIds;
    if (configured.isEmpty) {
      // Show all by default
      visibleFolders.assignAll(folders);
    } else {
      final configuredSet = configured.toSet();
      visibleFolders.assignAll(
        folders.where((f) => configuredSet.contains(f.id)),
      );
      // If config results in empty list, show all
      if (visibleFolders.isEmpty) {
        visibleFolders.assignAll(folders);
      }
    }
  }

  Future<void> loadVideosForFolder(int folderId) async {
    tabLoading[folderId] = true;
    tabPage[folderId] = 1;
    try {
      final result = await _repo.getFavResources(mediaId: folderId, pn: 1);
      tabVideos[folderId] = result.items;
      tabHasMore[folderId] = result.hasMore;
    } catch (_) {
      tabVideos[folderId] = [];
      tabHasMore[folderId] = false;
    }
    tabLoading[folderId] = false;
  }

  Future<void> loadMoreForFolder(int folderId) async {
    if (!(tabHasMore[folderId] ?? false)) return;
    if (tabLoading[folderId] ?? false) return;
    final page = (tabPage[folderId] ?? 1) + 1;
    tabPage[folderId] = page;
    try {
      final result = await _repo.getFavResources(mediaId: folderId, pn: page);
      final existing = tabVideos[folderId] ?? [];
      tabVideos[folderId] = [...existing, ...result.items];
      tabHasMore[folderId] = result.hasMore;
    } catch (_) {
      tabHasMore[folderId] = false;
    }
  }

  void playVideo(FavResourceModel video) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromSearch(video.toSearchVideoModel());
  }

  void toggleFolderVisibility(int folderId, bool visible) {
    final configured = _storage.playlistVisibleFolderIds.toList();
    if (configured.isEmpty) {
      // First time configuring: start with all IDs then toggle
      final allIds = folders.map((f) => f.id).toList();
      if (!visible) {
        allIds.remove(folderId);
      }
      _storage.playlistVisibleFolderIds = allIds;
    } else {
      if (visible && !configured.contains(folderId)) {
        configured.add(folderId);
      } else if (!visible) {
        configured.remove(folderId);
      }
      _storage.playlistVisibleFolderIds = configured;
    }
    _applyVisibleConfig();
  }

  void saveVisibleConfig(List<int> visibleIds) {
    _storage.playlistVisibleFolderIds = visibleIds;
    _applyVisibleConfig();
  }

  Future<bool> createFolder(String title, {String intro = '', int privacy = 0}) async {
    final ok = await _repo.addFavFolder(
      title: title,
      intro: intro,
      privacy: privacy,
    );
    if (ok) {
      await loadFolders();
    }
    return ok;
  }
}
