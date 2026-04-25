import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class CoverColorService {
  static final CoverColorService _instance = CoverColorService._();
  factory CoverColorService() => _instance;
  CoverColorService._();

  final _cache = <String, Color>{};
  static const _maxCacheSize = 50;

  Future<Color?> extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return null;

    final normalizedUrl =
        imageUrl.startsWith('//') ? 'https:$imageUrl' : imageUrl;

    if (_cache.containsKey(normalizedUrl)) {
      return _cache[normalizedUrl];
    }

    try {
      final provider = CachedNetworkImageProvider(normalizedUrl);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const ui.Size(100, 100),
        maximumColorCount: 16,
      );

      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;

      if (color != null) {
        if (_cache.length >= _maxCacheSize) {
          _cache.remove(_cache.keys.first);
        }
        _cache[normalizedUrl] = color;
      }

      return color;
    } catch (_) {
      return null;
    }
  }
}
