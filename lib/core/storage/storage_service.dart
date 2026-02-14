import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  // Clear all auth data
  void clearAuth() {
    _box.remove('user_info');
    _box.remove('is_logged_in');
    _box.remove('user_mid');
    _box.remove('access_key');
    _box.remove('access_key_mid');
  }
}
