import 'dart:developer';

import 'package:get/get.dart';

import '../../data/repositories/netease_repository.dart';

class NeteaseToplistController extends GetxController {
  final _neteaseRepo = Get.find<NeteaseRepository>();

  final toplists = <NeteaseToplistItem>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final result = await _neteaseRepo.getToplist();
      toplists.assignAll(result);
    } catch (e) {
      log('Load toplist error: $e');
    }
    isLoading.value = false;
  }

  Future<void> reload() async {
    await _loadData();
  }
}
