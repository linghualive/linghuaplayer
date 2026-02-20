import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/local_playlist_model.dart';
import '../models/search/search_video_model.dart';

class LocalPlaylistService {
  static const _storageKey = 'local_playlists';

  late final GetStorage _box;
  final playlists = <LocalPlaylist>[].obs;

  void init() {
    _box = GetStorage();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final raw = _box.read<List>(_storageKey);
    if (raw == null) return;
    playlists.assignAll(
      raw
          .map((e) => LocalPlaylist.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  void _saveToStorage() {
    _box.write(_storageKey, playlists.map((p) => p.toJson()).toList());
  }

  /// Create an empty local playlist.
  LocalPlaylist createPlaylist(String name, {String description = ''}) {
    final playlist = LocalPlaylist.create(
      name: name,
      description: description,
      sourceTag: 'local',
    );
    playlists.insert(0, playlist);
    _saveToStorage();
    return playlist;
  }

  /// Import a playlist from a remote platform.
  LocalPlaylist importPlaylist({
    required String name,
    String coverUrl = '',
    required String sourceTag,
    required String remoteId,
    required List<SearchVideoModel> tracks,
    String creatorName = '',
    String description = '',
  }) {
    final playlist = LocalPlaylist.create(
      name: name,
      coverUrl: coverUrl,
      sourceTag: sourceTag,
      remoteId: remoteId,
      creatorName: creatorName,
      description: description,
      tracksJson: tracks.map((t) => t.toJson()).toList(),
    );
    playlists.insert(0, playlist);
    _saveToStorage();
    return playlist;
  }

  /// Refresh tracks of an already-imported playlist.
  void refreshPlaylist(String localId, List<SearchVideoModel> newTracks) {
    final index = playlists.indexWhere((p) => p.id == localId);
    if (index < 0) return;
    playlists[index] = playlists[index].copyWith(
      tracksJson: newTracks.map((t) => t.toJson()).toList(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _saveToStorage();
  }

  /// Delete a playlist by id.
  void deletePlaylist(String id) {
    playlists.removeWhere((p) => p.id == id);
    _saveToStorage();
  }

  /// Rename a playlist.
  void renamePlaylist(String id, String newName) {
    final index = playlists.indexWhere((p) => p.id == id);
    if (index < 0) return;
    playlists[index] = playlists[index].copyWith(
      name: newName,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _saveToStorage();
  }

  /// Add a track to a playlist.
  void addTrack(String playlistId, SearchVideoModel track) {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final existing = playlists[index].tracksJson.toList();
    // Avoid duplicates
    final trackJson = track.toJson();
    final uniqueId = track.uniqueId;
    final alreadyExists = existing.any((t) {
      final model = SearchVideoModel.fromJson(t);
      return model.uniqueId == uniqueId;
    });
    if (alreadyExists) return;
    existing.add(trackJson);
    playlists[index] = playlists[index].copyWith(
      tracksJson: existing,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _saveToStorage();
  }

  /// Remove a track from a playlist by its uniqueId.
  void removeTrack(String playlistId, String trackUniqueId) {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final existing = playlists[index].tracksJson.toList();
    existing.removeWhere((t) {
      final model = SearchVideoModel.fromJson(t);
      return model.uniqueId == trackUniqueId;
    });
    playlists[index] = playlists[index].copyWith(
      tracksJson: existing,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _saveToStorage();
  }

  /// Find a playlist by remote source tag and remote id.
  LocalPlaylist? findByRemoteId(String sourceTag, String remoteId) {
    return playlists.firstWhereOrNull(
      (p) => p.sourceTag == sourceTag && p.remoteId == remoteId,
    );
  }

  /// Get playlists grouped by source tag.
  Map<String, List<LocalPlaylist>> get playlistsBySource {
    final map = <String, List<LocalPlaylist>>{};
    for (final p in playlists) {
      map.putIfAbsent(p.sourceTag, () => []).add(p);
    }
    return map;
  }

  /// Get a single playlist by id.
  LocalPlaylist? getPlaylist(String id) {
    return playlists.firstWhereOrNull((p) => p.id == id);
  }
}
