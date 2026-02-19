import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' as mk;

/// Unified output device type across platforms.
enum AudioOutputType {
  speaker,
  bluetooth,
  wired,
  airplay,
  usb,
  hdmi,
  unknown,
}

/// Represents a single audio output device.
class AudioOutputDevice {
  final String id;
  final String name;
  final AudioOutputType type;
  final bool isActive;

  const AudioOutputDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = false,
  });
}

/// Manages audio output device discovery and switching.
///
/// - iOS: uses AVRoutePickerView via MethodChannel (system picker)
/// - Android: uses system output switcher (13+) or AudioManager device list
/// - macOS/Linux: uses mpv audio-device properties via NativePlayer
class AudioOutputService {
  static const _channel =
      MethodChannel('com.flamekit.flamekit/audio_output');

  final devices = <AudioOutputDevice>[].obs;
  final activeDeviceName = ''.obs;

  mk.NativePlayer? _nativePlayer;

  /// Connect the mpv NativePlayer reference (desktop only).
  void connectNativePlayer(mk.NativePlayer nativePlayer) {
    _nativePlayer = nativePlayer;
  }

  /// Main entry point: show the output device picker.
  ///
  /// - iOS: triggers the system AVRoutePickerView
  /// - Android 13+: triggers the system media output dialog
  /// - Android <13 / desktop: shows a Flutter bottom sheet with device list
  Future<void> showOutputPicker() async {
    if (Platform.isIOS) {
      await _showIOSRoutePicker();
    } else if (Platform.isAndroid) {
      await _showAndroidOutputSwitcher();
    } else if (Platform.isMacOS || Platform.isLinux) {
      await _loadDesktopDevices();
    }
  }

  /// Whether the platform uses a native system picker (no Flutter sheet needed).
  bool get usesSystemPicker => Platform.isIOS;

  // ── iOS ──

  Future<void> _showIOSRoutePicker() async {
    try {
      await _channel.invokeMethod('showRoutePicker');
    } catch (e) {
      log('iOS showRoutePicker error: $e');
    }
  }

  // ── Android ──

  Future<void> _showAndroidOutputSwitcher() async {
    await _loadAndroidDevices();
  }

  Future<void> _loadAndroidDevices() async {
    try {
      final result = await _channel.invokeMethod<String>('getOutputDevices');
      if (result == null) return;

      final list = jsonDecode(result) as List<dynamic>;
      devices.value = list.map((d) {
        final map = d as Map<String, dynamic>;
        return AudioOutputDevice(
          id: map['id']?.toString() ?? '',
          name: map['name'] as String? ?? '',
          type: _parseType(map['type'] as String? ?? ''),
          isActive: map['isActive'] as bool? ?? false,
        );
      }).toList();

      final active = devices.firstWhereOrNull((d) => d.isActive);
      activeDeviceName.value = active?.name ?? '';
    } catch (e) {
      log('Android getOutputDevices error: $e');
    }
  }

  // ── Desktop (macOS / Linux via mpv) ──

  Future<void> _loadDesktopDevices() async {
    if (_nativePlayer == null) return;

    try {
      final listJson =
          await _nativePlayer!.getProperty('audio-device-list');
      final currentDevice =
          await _nativePlayer!.getProperty('audio-device');

      final list = jsonDecode(listJson) as List<dynamic>;
      devices.value = list.map((d) {
        final map = d as Map<String, dynamic>;
        final name = map['description'] as String? ?? map['name'] as String? ?? '';
        final id = map['name'] as String? ?? '';
        return AudioOutputDevice(
          id: id,
          name: name,
          type: _inferDesktopType(name, id),
          isActive: id == currentDevice,
        );
      }).toList();

      final active = devices.firstWhereOrNull((d) => d.isActive);
      activeDeviceName.value = active?.name ?? '';
    } catch (e) {
      log('Desktop audio device list error: $e');
    }
  }

  /// Switch to a specific device (desktop only, via mpv).
  Future<void> selectDevice(String deviceId) async {
    if (_nativePlayer == null) return;

    try {
      await _nativePlayer!.setProperty('audio-device', deviceId);
      // Refresh device list to update active state
      await _loadDesktopDevices();
    } catch (e) {
      log('Desktop selectDevice error: $e');
    }
  }

  // ── Helpers ──

  AudioOutputType _parseType(String type) {
    switch (type) {
      case 'speaker':
        return AudioOutputType.speaker;
      case 'bluetooth':
        return AudioOutputType.bluetooth;
      case 'wired':
        return AudioOutputType.wired;
      case 'airplay':
        return AudioOutputType.airplay;
      case 'usb':
        return AudioOutputType.usb;
      case 'hdmi':
        return AudioOutputType.hdmi;
      default:
        return AudioOutputType.unknown;
    }
  }

  AudioOutputType _inferDesktopType(String name, String id) {
    final lower = '${name.toLowerCase()} ${id.toLowerCase()}';
    if (lower.contains('bluetooth') || lower.contains('bt')) {
      return AudioOutputType.bluetooth;
    }
    if (lower.contains('headphone') || lower.contains('headset')) {
      return AudioOutputType.wired;
    }
    if (lower.contains('airplay')) {
      return AudioOutputType.airplay;
    }
    if (lower.contains('usb')) {
      return AudioOutputType.usb;
    }
    if (lower.contains('hdmi')) {
      return AudioOutputType.hdmi;
    }
    return AudioOutputType.speaker;
  }

  /// Get the icon for the current active output type.
  AudioOutputType get activeType {
    final active = devices.firstWhereOrNull((d) => d.isActive);
    return active?.type ?? AudioOutputType.speaker;
  }
}
