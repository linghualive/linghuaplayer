import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../storage/storage_service.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final String htmlUrl;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.htmlUrl,
  });

  bool get hasUpdate => _compareVersions(latestVersion, currentVersion) > 0;

  static int _compareVersions(String a, String b) {
    final aParts = a.replaceAll(RegExp(r'^v'), '').split('.');
    final bParts = b.replaceAll(RegExp(r'^v'), '').split('.');
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
      final bv = i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }
}

class UpdateService {
  static const _owner = 'linghualive';
  static const _repo = 'linghuaplayer';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final res = await _dio.get<Map<String, dynamic>>(_apiUrl);
      final data = res.data;
      if (data == null) return null;

      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';

      String downloadUrl = '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      return UpdateInfo(
        latestVersion: tagName,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: body,
        htmlUrl: htmlUrl,
      );
    } catch (e) {
      log('Update check failed: $e');
      return null;
    }
  }

  static Future<void> checkAndNotify() async {
    final storage = Get.find<StorageService>();
    final skipped = storage.skippedUpdateVersion;

    final info = await checkForUpdate();
    if (info == null || !info.hasUpdate) return;

    if (skipped == info.latestVersion) return;

    _showUpdateDialog(info);
  }

  /// Manual check from settings — always show result.
  static Future<void> manualCheck() async {
    final info = await checkForUpdate();
    if (info == null) {
      Get.snackbar('检查更新', '无法连接到服务器',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!info.hasUpdate) {
      Get.snackbar('检查更新', '当前已是最新版本 (${info.currentVersion})',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _showUpdateDialog(info);
  }

  static void _showUpdateDialog(UpdateInfo info) {
    Get.dialog(
      AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${info.currentVersion} → ${info.latestVersion}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (info.releaseNotes.isNotEmpty) ...[
              const Text('更新内容：',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final storage = Get.find<StorageService>();
              storage.skippedUpdateVersion = info.latestVersion;
              Get.back();
            },
            child: const Text('跳过此版本'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('稍后提醒'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              final url = info.downloadUrl.isNotEmpty
                  ? info.downloadUrl
                  : info.htmlUrl;
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: const Text('前往下载'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
