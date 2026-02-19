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

  static const double _itemExtent = 56.0;

  @override
  void dispose() {
    _scrollController.dispose();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _onScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      setState(() => _isUserScrolling = true);
      _resumeTimer?.cancel();
    }
  }

  void _onScrollUpdate(ScrollUpdateNotification notification) {
    if (!_isUserScrolling) return;
    final offset = _scrollController.offset;
    // With centered padding, item i is at offset i * _itemExtent
    // Center of viewport maps to index = offset / _itemExtent (rounded)
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
      }
    });
  }

  void _seekToCenterLine() {
    final lines = _controller.lyrics.value?.lines;
    if (lines == null || _centerLineIndex < 0 || _centerLineIndex >= lines.length) return;
    _controller.seekTo(lines[_centerLineIndex].timestamp);
    _resumeTimer?.cancel();
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

      // Still loading
      if (isLoading && lyrics == null) {
        return const Center(
          child: Text(
            '歌词加载中...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Finished loading, no lyrics found
      if (lyrics == null) {
        return const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Plain lyrics only (no sync)
      if (!lyrics.hasSyncedLyrics) {
        if (lyrics.plainLyrics != null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              lyrics.plainLyrics!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 2.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );
        }
        return const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      // Synced lyrics
      final currentIndex = _controller.currentLyricsIndex.value;
      final lines = lyrics.lines;

      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          // Padding so that any line (including first/last) can be centered
          final verticalPadding = viewportHeight / 2 - _itemExtent / 2;

          // Auto-scroll to current line (skip if user is scrolling)
          if (!_isUserScrolling) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (currentIndex >= 0 && _scrollController.hasClients) {
                final targetOffset = currentIndex * _itemExtent;
                _scrollController.animateTo(
                  targetOffset.clamp(
                    0.0,
                    _scrollController.position.maxScrollExtent,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }

          final listView = NotificationListener<ScrollNotification>(
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
                horizontal: 32,
                vertical: verticalPadding,
              ),
              itemCount: lines.length,
              itemExtent: _itemExtent,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isCurrent = index == currentIndex;
                final isPast = index < currentIndex;

                return GestureDetector(
                  onTap: () => _controller.seekTo(line.timestamp),
                  child: Container(
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: isCurrent ? 20 : 14,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : isPast
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      child: Text(
                        line.text,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          );

          // When user is scrolling, overlay a time indicator at the center
          if (!_isUserScrolling) return listView;

          final centerTimestamp = (_centerLineIndex >= 0 && _centerLineIndex < lines.length)
              ? lines[_centerLineIndex].timestamp
              : Duration.zero;

          return Stack(
            children: [
              listView,
              // Rectangular highlight indicator at center
              Center(
                child: IgnorePointer(
                  ignoring: false,
                  child: GestureDetector(
                    onTap: _seekToCenterLine,
                    child: Container(
                      width: double.infinity,
                      height: _itemExtent,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(centerTimestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 22,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
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
