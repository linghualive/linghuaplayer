import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../player_controller.dart';

class PlayerLyrics extends StatefulWidget {
  const PlayerLyrics({super.key});

  @override
  State<PlayerLyrics> createState() => _PlayerLyricsState();
}

class _PlayerLyricsState extends State<PlayerLyrics> {
  final _scrollController = ScrollController();
  final _controller = Get.find<PlayerController>();

  bool _isUserScrolling = false;
  int _centerLineIndex = 0;
  Timer? _resumeTimer;
  Worker? _autoScrollWorker;

  static const double _itemExtent = 56.0;

  @override
  void initState() {
    super.initState();
    _autoScrollWorker = ever(
      _controller.currentLyricsIndex,
      _autoScrollToIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _controller.currentLyricsIndex.value;
      if (index >= 0 && _scrollController.hasClients) {
        final offset = index * _itemExtent;
        _scrollController
            .jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _autoScrollWorker?.dispose();
    _scrollController.dispose();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _autoScrollToIndex(int index) {
    if (_isUserScrolling || index < 0) return;
    if (!_scrollController.hasClients) return;
    final targetOffset = index * _itemExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      _resumeTimer?.cancel();
      setState(() => _isUserScrolling = true);
    }
  }

  void _onScrollUpdate(ScrollUpdateNotification notification) {
    if (!_isUserScrolling) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemExtent).round();
    final lines = _controller.lyrics.value?.lines;
    if (lines == null) return;
    final clampedIndex = index.clamp(0, lines.length - 1);
    if (clampedIndex != _centerLineIndex) {
      setState(() => _centerLineIndex = clampedIndex);
    }
  }

  void _onScrollEnd(ScrollEndNotification notification) {
    if (!_isUserScrolling) return;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isUserScrolling = false);
        _autoScrollToIndex(_controller.currentLyricsIndex.value);
      }
    });
  }

  void _seekToCenterLine() {
    final lines = _controller.lyrics.value?.lines;
    if (lines == null ||
        _centerLineIndex < 0 ||
        _centerLineIndex >= lines.length) {
      return;
    }
    _controller.seekTo(lines[_centerLineIndex].timestamp);
    _resumeTimer?.cancel();
    _controller.currentLyricsIndex.value = _centerLineIndex;
    setState(() => _isUserScrolling = false);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final lyrics = _controller.lyrics.value;
      final isLoading = _controller.lyricsLoading.value;

      if (isLoading && lyrics == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '歌词加载中',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      }

      if (lyrics == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 8),
              Text(
                '暂无歌词',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        );
      }

      if (!lyrics.hasSyncedLyrics) {
        if (lyrics.plainLyrics != null) {
          return ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.06, 0.94, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Text(
                lyrics.plainLyrics!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 2.0,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 8),
              Text(
                '暂无歌词',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        );
      }

      final currentIndex = _controller.currentLyricsIndex.value;
      final lines = lyrics.lines;

      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final verticalPadding = viewportHeight / 2 - _itemExtent / 2;

          final centerTimestamp =
              (_isUserScrolling &&
                      _centerLineIndex >= 0 &&
                      _centerLineIndex < lines.length)
                  ? lines[_centerLineIndex].timestamp
                  : null;

          return Stack(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.12, 0.88, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _onScrollStart(notification);
                    } else if (notification is ScrollUpdateNotification) {
                      _onScrollUpdate(notification);
                    } else if (notification is ScrollEndNotification) {
                      _onScrollEnd(notification);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: verticalPadding,
                    ),
                    itemCount: lines.length,
                    itemExtent: _itemExtent,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final isCurrent = index == currentIndex;
                      final isPast = index < currentIndex;
                      final distance = (index - currentIndex).abs();

                      final opacity = isCurrent
                          ? 1.0
                          : isPast
                              ? (0.3 - distance * 0.03).clamp(0.12, 0.3)
                              : (0.65 - distance * 0.06).clamp(0.15, 0.65);

                      return Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: isCurrent ? 19 : 14,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.normal,
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: opacity),
                            shadows: isCurrent
                                ? [
                                    Shadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            line.text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_isUserScrolling && centerTimestamp != null)
                Center(
                  child: SizedBox(
                    height: _itemExtent,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(centerTimestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            thickness: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _seekToCenterLine,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}
