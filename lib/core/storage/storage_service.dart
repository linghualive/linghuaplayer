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

  // Clear all auth data
  void clearAuth() {
    _box.remove('user_info');
    _box.remove('is_logged_in');
    _box.remove('user_mid');
    _box.remove('access_key');
    _box.remove('access_key_mid');
  }
}
