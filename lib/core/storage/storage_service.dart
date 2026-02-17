import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/search/search_video_model.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    await GetStorage.init();
    return this;
  }

  // WBI keys
  String? getImgKey() => _box.read<String>('wbi_img_key');
  String? getSubKey() => _box.read<String>('wbi_sub_key');
  String? getWbiKeyDate() => _box.read<String>('wbi_key_date');

  void setWbiKeys(String imgKey, String subKey, String date) {
    _box.write('wbi_img_key', imgKey);
    _box.write('wbi_sub_key', subKey);
    _box.write('wbi_key_date', date);
  }

  // Access key
  String? getAccessKey() => _box.read<String>('access_key');
  String? getAccessKeyMid() => _box.read<String>('access_key_mid');

  void setAccessKey(String key, {String? mid}) {
    _box.write('access_key', key);
    if (mid != null) _box.write('access_key_mid', mid);
  }

  // User info
  Map<String, dynamic>? getUserInfo() =>
      _box.read<Map<String, dynamic>>('user_info');

  void setUserInfo(Map<String, dynamic> info) {
    _box.write('user_info', info);
  }

  bool get isLoggedIn => _box.read<bool>('is_logged_in') ?? false;

  set isLoggedIn(bool value) => _box.write('is_logged_in', value);

  // User mid
  String? get userMid => _box.read<String>('user_mid');

  set userMid(String? value) => _box.write('user_mid', value);

  // Search history
  static const _searchHistoryKey = 'search_history';
  static const _maxHistory = 20;

  List<String> getSearchHistory() {
    final list = _box.read<List>(_searchHistoryKey);
    if (list == null) return [];
    return list.cast<String>();
  }

  void addSearchHistory(String keyword) {
    final list = getSearchHistory();
    list.remove(keyword);
    list.insert(0, keyword);
    if (list.length > _maxHistory) {
      list.removeRange(_maxHistory, list.length);
    }
    _box.write(_searchHistoryKey, list);
  }

  void removeSearchHistory(String keyword) {
    final list = getSearchHistory();
    list.remove(keyword);
    _box.write(_searchHistoryKey, list);
  }

  void clearSearchHistory() {
    _box.remove(_searchHistoryKey);
  }

  // Play history
  static const _playHistoryKey = 'play_history';
  static const _maxPlayHistory = 200;

  List<Map<String, dynamic>> getPlayHistory() {
    final list = _box.read<List>(_playHistoryKey);
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void addPlayHistory(SearchVideoModel video) {
    final list = getPlayHistory();
    list.removeWhere((e) {
      final v = e['video'] as Map<String, dynamic>?;
      if (v == null) return false;
      final model = SearchVideoModel.fromJson(v);
      return model.uniqueId == video.uniqueId;
    });
    list.insert(0, {
      'video': video.toJson(),
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (list.length > _maxPlayHistory) {
      list.removeRange(_maxPlayHistory, list.length);
    }
    _box.write(_playHistoryKey, list);
  }

  void removePlayHistory(String uniqueId) {
    final list = getPlayHistory();
    list.removeWhere((e) {
      final v = e['video'] as Map<String, dynamic>?;
      if (v == null) return false;
      final model = SearchVideoModel.fromJson(v);
      return model.uniqueId == uniqueId;
    });
    _box.write(_playHistoryKey, list);
  }

  void clearPlayHistory() {
    _box.remove(_playHistoryKey);
  }

  // Theme settings
  int get themeMode => _box.read<int>('theme_mode') ?? 0;
  set themeMode(int value) => _box.write('theme_mode', value);

  bool get dynamicColor => _box.read<bool>('dynamic_color') ?? false;
  set dynamicColor(bool value) => _box.write('dynamic_color', value);

  int get customColor => _box.read<int>('custom_color') ?? 0;
  set customColor(int value) => _box.write('custom_color', value);

  // Video playback
  bool get enableVideo => _box.read<bool>('enable_video') ?? false;
  set enableVideo(bool value) => _box.write('enable_video', value);

  // Grid settings
  int get customRows => _box.read<int>('custom_rows') ?? 2;
  set customRows(int value) => _box.write('custom_rows', value);

  // Playlist visible folder IDs
  List<int> get playlistVisibleFolderIds {
    final list = _box.read<List>('playlist_visible_folder_ids');
    if (list == null) return [];
    return list.cast<int>();
  }

  set playlistVisibleFolderIds(List<int> value) =>
      _box.write('playlist_visible_folder_ids', value);

  // Playlist view mode (0=category, 1=mixed)
  int get playlistViewMode => _box.read<int>('playlist_view_mode') ?? 0;
  set playlistViewMode(int value) => _box.write('playlist_view_mode', value);

  // Update
  String? get skippedUpdateVersion =>
      _box.read<String>('skipped_update_version');
  set skippedUpdateVersion(String? value) =>
      _box.write('skipped_update_version', value);

  // DeepSeek API
  String? get deepseekApiKey => _box.read<String>('deepseek_api_key');
  set deepseekApiKey(String? value) {
    if (value == null) {
      _box.remove('deepseek_api_key');
    } else {
      _box.write('deepseek_api_key', value);
    }
  }

  List<String> get preferenceTags {
    final list = _box.read<List>('preference_tags');
    if (list == null) return [];
    return list.cast<String>();
  }

  set preferenceTags(List<String> value) =>
      _box.write('preference_tags', value);

  // Clear all auth data (Bilibili only)
  void clearAuth() {
    _box.remove('user_info');
    _box.remove('is_logged_in');
    _box.remove('user_mid');
    _box.remove('access_key');
    _box.remove('access_key_mid');
  }

  // NetEase Cloud Music auth
  bool get isNeteaseLoggedIn =>
      _box.read<bool>('netease_is_logged_in') ?? false;

  set isNeteaseLoggedIn(bool value) =>
      _box.write('netease_is_logged_in', value);

  String? get neteaseUserId => _box.read<String>('netease_user_id');

  set neteaseUserId(String? value) => _box.write('netease_user_id', value);

  Map<String, dynamic>? getNeteaseUserInfo() =>
      _box.read<Map<String, dynamic>>('netease_user_info');

  void setNeteaseUserInfo(Map<String, dynamic> info) {
    _box.write('netease_user_info', info);
  }

  void clearNeteaseAuth() {
    _box.remove('netease_user_info');
    _box.remove('netease_is_logged_in');
    _box.remove('netease_user_id');
  }

  // QQ Music auth
  bool get isQqMusicLoggedIn =>
      _box.read<bool>('qqmusic_is_logged_in') ?? false;

  set isQqMusicLoggedIn(bool value) =>
      _box.write('qqmusic_is_logged_in', value);

  String? get qqMusicUin => _box.read<String>('qqmusic_uin');

  set qqMusicUin(String? value) => _box.write('qqmusic_uin', value);

  String? get qqMusicPSkey => _box.read<String>('qqmusic_p_skey');

  set qqMusicPSkey(String? value) => _box.write('qqmusic_p_skey', value);

  Map<String, dynamic>? getQqMusicUserInfo() =>
      _box.read<Map<String, dynamic>>('qqmusic_user_info');

  void setQqMusicUserInfo(Map<String, dynamic> info) {
    _box.write('qqmusic_user_info', info);
  }

  void clearQqMusicAuth() {
    _box.remove('qqmusic_user_info');
    _box.remove('qqmusic_is_logged_in');
    _box.remove('qqmusic_uin');
    _box.remove('qqmusic_p_skey');
  }
}
