import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/utils/app_toast.dart';
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
    final aParts = a.replaceAll(RegExp(r'^v'), '').split('+').first.split('.');
    final bParts = b.replaceAll(RegExp(r'^v'), '').split('+').first.split('.');
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
  static const _updateChannel =
      MethodChannel('com.flamekit.flamekit/app_update');

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
      AppToast.show('无法连接到服务器');
      return;
    }
    if (!info.hasUpdate) {
      AppToast.show('当前已是最新版本 (${info.currentVersion})');
      return;
    }
    _showUpdateDialog(info);
  }

  static String _mirrorUrl(String url) {
    if (url.startsWith('https://github.com/')) {
      return 'https://gh.llkk.cc/$url';
    }
    return url;
  }

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _downloadAndInstall(UpdateInfo info) async {
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/update.apk';

    final progress = ValueNotifier<double>(0);
    final status = ValueNotifier<_DownloadStatus>(_DownloadStatus.downloading);

    _showDownloadProgress(progress, status, () {
      _downloadAndInstall(info);
    });

    try {
      final downloadDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        maxRedirects: 5,
      ));

      // Try mirror first, fallback to direct URL
      final mirrorUrl = _mirrorUrl(info.downloadUrl);
      final urls = mirrorUrl != info.downloadUrl
          ? [mirrorUrl, info.downloadUrl]
          : [info.downloadUrl];

      bool downloaded = false;
      for (final url in urls) {
        try {
          log('Downloading APK from: $url');
          progress.value = 0;
          await downloadDio.download(
            url,
            savePath,
            onReceiveProgress: (received, total) {
              if (total > 0) {
                progress.value = received / total;
              }
            },
          );
          downloaded = true;
          break;
        } catch (e) {
          log('Download failed from $url: $e');
          // Try next URL
        }
      }

      if (!downloaded) {
        status.value = _DownloadStatus.failed;
        return;
      }

      status.value = _DownloadStatus.installing;

      try {
        await _updateChannel.invokeMethod('installApk', {
          'filePath': savePath,
        });
      } catch (e) {
        log('Install APK failed: $e');
        status.value = _DownloadStatus.failed;
      }
    } catch (e) {
      log('Download failed: $e');
      status.value = _DownloadStatus.failed;
    }
  }

  static void _showDownloadProgress(
    ValueNotifier<double> progress,
    ValueNotifier<_DownloadStatus> status,
    VoidCallback onRetry,
  ) {
    Get.bottomSheet(
      PopScope(
        canPop: false,
        child: ValueListenableBuilder<_DownloadStatus>(
          valueListenable: status,
          builder: (context, currentStatus, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentStatus == _DownloadStatus.failed
                            ? Icons.error_outline
                            : Icons.system_update,
                        color: currentStatus == _DownloadStatus.failed
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentStatus == _DownloadStatus.downloading
                            ? '正在下载更新...'
                            : currentStatus == _DownloadStatus.installing
                                ? '下载完成，正在安装...'
                                : '下载失败',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentStatus == _DownloadStatus.downloading)
                    ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (context, value, _) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(value * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                  if (currentStatus == _DownloadStatus.installing)
                    const LinearProgressIndicator(),
                  if (currentStatus == _DownloadStatus.failed) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Get.back();
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
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
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: info.releaseNotes,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
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
              if (_isAndroid && info.downloadUrl.isNotEmpty) {
                _downloadAndInstall(info);
              } else {
                final url = info.downloadUrl.isNotEmpty
                    ? info.downloadUrl
                    : info.htmlUrl;
                launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Text(_isAndroid ? '立即更新' : '前往下载'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

enum _DownloadStatus {
  downloading,
  installing,
  failed,
}
