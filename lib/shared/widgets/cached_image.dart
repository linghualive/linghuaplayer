import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  String _normalizeUrl(String url) {
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(context);
    }

    final widget = CachedNetworkImage(
      imageUrl: _normalizeUrl(imageUrl!),
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        highlightColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(context),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: widget);
    }
    return widget;
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 20,
        color: theme.colorScheme.outline.withValues(alpha: 0.4),
      ),
    );
  }
}
