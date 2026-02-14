import 'dart:developer';

import 'package:get/get.dart';

import '../../data/models/music/audio_song_model.dart';
import '../../data/models/music/hot_playlist_model.dart';
import '../../data/models/music/playlist_detail_model.dart';
import '../../data/repositories/music_repository.dart';
import '../player/player_controller.dart';

class AudioPlaylistDetailController extends GetxController {
  final _musicRepo = Get.find<MusicRepository>();

  final songs = <AudioSongModel>[].obs;
  final detail = Rxn<PlaylistDetailModel>();
  final isLoading = true.obs;

  late final int menuId;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is HotPlaylistModel) {
      menuId = args.menuId;
      title = args.title;
    } else {
      menuId = 0;
      title = '';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadDetail(),
        _loadSongs(),
      ]);
    } catch (e) {
      log('Load playlist detail error: $e');
    }
    isLoading.value = false;
  }

  Future<void> _loadDetail() async {
    final info = await _musicRepo.getPlaylistInfo(menuId);
    if (info != null) {
      detail.value = info;
    }
  }

  Future<void> _loadSongs() async {
    final list = await _musicRepo.getPlaylistSongs(menuId);
    songs.assignAll(list);
  }

  Future<void> reload() async {
    await _loadData();
  }

  void playSong(AudioSongModel song) {
    final playerCtrl = Get.find<PlayerController>();
    playerCtrl.playFromAudioSong(song);
  }

  void playAll() {
    if (songs.isEmpty) return;
    final playerCtrl = Get.find<PlayerController>();
    // Play the first song
    playerCtrl.playFromAudioSong(songs.first);
    // Add the rest to queue
    for (int i = 1; i < songs.length; i++) {
      playerCtrl.addToQueue(songs[i].toSearchVideoModel());
    }
  }
}
