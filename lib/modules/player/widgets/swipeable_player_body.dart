import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cached_image.dart';
import '../player_controller.dart';

class SwipeablePlayerBody extends StatefulWidget {
  final Widget Function() buildArtworkArea;
  final Widget controlsArea;

  const SwipeablePlayerBody({
    super.key,
    required this.buildArtworkArea,
    required this.controlsArea,
  });

  @override
  State<SwipeablePlayerBody> createState() => _SwipeablePlayerBodyState();
}

class _SwipeablePlayerBodyState extends State<SwipeablePlayerBody> {
  final _controller = Get.find<PlayerController>();
  late final PageController _pageController;
  bool _isUserSwiping = false;
  Worker? _trackChangeWorker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);

    _trackChangeWorker = ever(_controller.currentVideo, (_) {
      if (!_isUserSwiping && mounted && _pageController.hasClients) {
        final page = _pageController.page?.round() ?? 1;
        if (page == 1) {
          _pageController
              .animateToPage(2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut)
              .then((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(1);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _trackChangeWorker?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == 1) return;

    _isUserSwiping = true;
    HapticFeedback.mediumImpact();

    if (index == 0) {
      _controller.skipPrevious();
    } else if (index == 2) {
      _controller.skipNext();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(1);
      }
      _isUserSwiping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showLyrics = _controller.showLyrics.value;
      final isLoading = _controller.isLoading.value;

      final canSwipe = !showLyrics && !isLoading;

      return PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: canSwipe
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemCount: 3,
        itemBuilder: (context, index) {
          if (index == 1) {
            return _buildCurrentPage();
          }
          return _buildPreviewPage(index == 0);
        },
      );
    });
  }

  Widget _buildCurrentPage() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: widget.buildArtworkArea(),
        ),
        const SizedBox(height: 16),
        Expanded(flex: 4, child: widget.controlsArea),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreviewPage(bool isPrevious) {
    return Obx(() {
      final video = isPrevious
          ? (_controller.playHistory.isNotEmpty
              ? _controller.playHistory.last.video
              : null)
          : (_controller.queue.length > 1
              ? _controller.queue[1].video
              : null);

      if (video == null) {
        return _buildEmptyPreview(isPrevious);
      }

      return _SongPreviewCard(
        imageUrl: video.pic,
        title: video.title,
        artist: video.author,
        isPrevious: isPrevious,
      );
    });
  }

  Widget _buildEmptyPreview(bool isPrevious) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrevious ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            size: 32,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            isPrevious ? '没有上一首了' : '没有更多了',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongPreviewCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final bool isPrevious;

  const _SongPreviewCard({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.isPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPrevious) ...[
              Icon(
                Icons.keyboard_arrow_down,
                size: 28,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (!isPrevious) ...[
              const SizedBox(height: 12),
              Icon(
                Icons.keyboard_arrow_up,
                size: 28,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
