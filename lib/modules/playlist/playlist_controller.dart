import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../data/models/user/fav_folder_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../data/repositories/qqmusic_repository.dart';
import '../../data/repositories/user_repository.dart';

class PlaylistController extends GetxController {
  final _repo = Get.find<UserRepository>();
  final _neteaseRepo = Get.find<NeteaseRepository>();
  final _qqMusicRepo = Get.find<QqMusicRepository>();
  final _storage = Get.find<StorageService>();

  final folders = <FavFolderModel>[].obs;
  final visibleFolders = <FavFolderModel>[].obs;
  final isLoading = true.obs;

  // Netease playlist state
  final neteasePlaylists = <NeteasePlaylistBrief>[].obs;
  final neteaseIsLoading = true.obs;

  // QQ Music playlist state
  final qqMusicPlaylists = <QqMusicPlaylistBrief>[].obs;
  final qqMusicIsLoading = true.obs;

  // Search
  final searchQuery = ''.obs;

  List<FavFolderModel> get filteredFolders {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return visibleFolders;
    return visibleFolders
        .where((f) => f.title.toLowerCase().contains(query))
        .toList();
  }

  List<NeteasePlaylistBrief> get filteredNeteasePlaylists {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return neteasePlaylists;
    return neteasePlaylists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  List<QqMusicPlaylistBrief> get filteredQqMusicPlaylists {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) return qqMusicPlaylists;
    return qqMusicPlaylists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadFolders();
    loadNeteasePlaylists();
    loadQqMusicPlaylists();
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
    } catch (_) {}
    isLoading.value = false;
  }

  void _applyVisibleConfig() {
    final configured = _storage.playlistVisibleFolderIds;
    if (configured.isEmpty) {
      visibleFolders.assignAll(folders);
    } else {
      final configuredSet = configured.toSet();
      visibleFolders.assignAll(
        folders.where((f) => configuredSet.contains(f.id)),
      );
      if (visibleFolders.isEmpty) {
        visibleFolders.assignAll(folders);
      }
    }
  }

  void toggleFolderVisibility(int folderId, bool visible) {
    final configured = _storage.playlistVisibleFolderIds.toList();
    if (configured.isEmpty) {
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
    final folderId = await _repo.addFavFolder(
      title: title,
      intro: intro,
      privacy: privacy,
    );
    if (folderId != null) {
      await loadFolders();
      return true;
    }
    return false;
  }

  // ── Netease Playlist Methods ──────────────────────────

  Future<void> loadNeteasePlaylists() async {
    neteaseIsLoading.value = true;
    final uid = int.tryParse(_storage.neteaseUserId ?? '') ?? 0;
    if (uid == 0) {
      neteaseIsLoading.value = false;
      return;
    }
    try {
      final list = await _neteaseRepo.getUserPlaylists(uid);
      neteasePlaylists.assignAll(list);
    } catch (_) {}
    neteaseIsLoading.value = false;
  }

  Future<void> loadQqMusicPlaylists() async {
    qqMusicIsLoading.value = true;
    final uin = _storage.qqMusicUin ?? '';
    if (uin.isEmpty) {
      qqMusicIsLoading.value = false;
      return;
    }
    try {
      final list = await _qqMusicRepo.getUserPlaylists(uin);
      qqMusicPlaylists.assignAll(list);
    } catch (_) {}
    qqMusicIsLoading.value = false;
  }
}
