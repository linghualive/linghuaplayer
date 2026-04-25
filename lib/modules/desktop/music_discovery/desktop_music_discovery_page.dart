import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/browse_models.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../music_discovery/music_discovery_controller.dart';
import '../../music_discovery/widgets/section_header.dart';

class DesktopMusicDiscoveryPage extends GetView<MusicDiscoveryController> {
  const DesktopMusicDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.curatedPlaylists.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAll(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildDesktopSearchHeader(context),
              ),
              if (controller.curatedPlaylists.isNotEmpty) ...[
                _buildSectionSliver('精选歌单推荐'),
                _buildPlaylistsGrid(),
              ],
              if (controller.curatedPlaylists.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_music_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          '暂无推荐内容',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktopSearchHeader(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = Breakpoints.getScreenPadding(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top + 16,
            padding.right,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.search),
                  child: Container(
                    height: 48,
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 24,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '搜索音乐、歌手、专辑',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ctrl+K',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _buildSectionSliver(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SectionHeader(title: title),
      ),
    );
  }

  Widget _buildPlaylistsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns =
              Breakpoints.getGridColumns(constraints.crossAxisExtent)
                  .clamp(3, 6);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final playlist = controller.curatedPlaylists[index];
                return _DesktopPlaylistCard(
                  playlist: playlist,
                  onTap: () => controller.navigateToPlaylist(playlist),
                );
              },
              childCount: controller.curatedPlaylists.length,
            ),
          );
        },
      ),
    );
  }
}

class _DesktopPlaylistCard extends StatefulWidget {
  final PlaylistBrief playlist;
  final VoidCallback? onTap;

  const _DesktopPlaylistCard({required this.playlist, this.onTap});

  @override
  State<_DesktopPlaylistCard> createState() => _DesktopPlaylistCardState();
}

class _DesktopPlaylistCardState extends State<_DesktopPlaylistCard> {
  bool _hovered = false;

  String _formatCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor
                            .withValues(alpha: _hovered ? 0.18 : 0.08),
                        blurRadius: _hovered ? 16 : 8,
                        offset: Offset(0, _hovered ? 6 : 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedImage(
                        imageUrl: widget.playlist.coverUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (widget.playlist.playCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  _formatCount(widget.playlist.playCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.playlist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
