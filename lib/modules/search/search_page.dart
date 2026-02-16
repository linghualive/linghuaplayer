import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/search/search_video_model.dart';
import '../../data/repositories/netease_repository.dart';
import '../../shared/widgets/empty_widget.dart';
import '../player/player_controller.dart';
import 'search_controller.dart' as app;
import 'widgets/hot_search_list.dart';
import 'widgets/search_suggestion_list.dart';
import 'widgets/search_result_card.dart';

class SearchPage extends GetView<app.SearchController> {
  final bool isEmbedded;

  const SearchPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isEmbedded,
        toolbarHeight: 64,
        title: Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SearchBar(
            controller: controller.searchTextController,
            focusNode: controller.focusNode,
            hintText: '搜索音乐...',
            textStyle: WidgetStateProperty.all(
              Theme.of(context).textTheme.bodyLarge,
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: [
              Obx(() {
                if (controller.currentKeyword.isNotEmpty ||
                    controller.searchTextController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: controller.clearSearch,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
            onSubmitted: controller.search,
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case app.SearchState.hot:
            return const HotSearchList();
          case app.SearchState.suggesting:
            return const SearchSuggestionList();
          case app.SearchState.empty:
            return Column(
              children: [
                _buildSourceChips(),
                if (controller.searchSource.value == MusicSource.netease)
                  _buildNeteaseTypeChips(),
                const Expanded(child: EmptyWidget(message: '未找到结果')),
              ],
            );
          case app.SearchState.results:
            return _buildResults();
        }
      }),
    );
  }

  Widget _buildSourceChips() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('网易云'),
                selected:
                    controller.searchSource.value == MusicSource.netease,
                onSelected: (_) =>
                    controller.switchSource(MusicSource.netease),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('B站'),
                selected:
                    controller.searchSource.value == MusicSource.bilibili,
                onSelected: (_) =>
                    controller.switchSource(MusicSource.bilibili),
              ),
            ],
          ),
        ));
  }

  Widget _buildNeteaseTypeChips() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('歌曲'),
                  selected: controller.neteaseSearchType.value ==
                      app.NeteaseSearchType.song,
                  onSelected: (_) => controller
                      .switchNeteaseSearchType(app.NeteaseSearchType.song),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('歌手'),
                  selected: controller.neteaseSearchType.value ==
                      app.NeteaseSearchType.artist,
                  onSelected: (_) => controller
                      .switchNeteaseSearchType(app.NeteaseSearchType.artist),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('专辑'),
                  selected: controller.neteaseSearchType.value ==
                      app.NeteaseSearchType.album,
                  onSelected: (_) => controller
                      .switchNeteaseSearchType(app.NeteaseSearchType.album),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('歌单'),
                  selected: controller.neteaseSearchType.value ==
                      app.NeteaseSearchType.playlist,
                  onSelected: (_) => controller
                      .switchNeteaseSearchType(app.NeteaseSearchType.playlist),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildResults() {
    return Column(
      children: [
        _buildSourceChips(),
        Obx(() {
          if (controller.searchSource.value == MusicSource.netease) {
            return _buildNeteaseTypeChips();
          }
          return const SizedBox.shrink();
        }),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                controller.loadMore();
              }
              return false;
            },
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.allResults.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: controller.allResults.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.allResults.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildResultItem(context, index);
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, int index) {
    final item = controller.allResults[index];

    if (item is SearchVideoModel) {
      if (item.isNetease) {
        return _buildNeteaseSongCard(context, item);
      }
      return SearchResultCard(video: item);
    }
    if (item is NeteaseArtistBrief) {
      return _buildArtistCard(context, item);
    }
    if (item is NeteaseAlbumBrief) {
      return _buildAlbumCard(context, item);
    }
    if (item is NeteasePlaylistBrief) {
      return _buildPlaylistCard(context, item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNeteaseSongCard(BuildContext context, SearchVideoModel song) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.music_note, size: 20, color: theme.colorScheme.outline),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.author + (song.description.isNotEmpty ? ' · ${song.description}' : ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Text(
        song.duration,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      onTap: () {
        final playerCtrl = Get.find<PlayerController>();
        playerCtrl.playFromSearch(song);
      },
    );
  }

  Widget _buildArtistCard(BuildContext context, NeteaseArtistBrief artist) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: artist.picUrl.isNotEmpty
            ? CachedNetworkImageProvider(artist.picUrl)
            : null,
        child: artist.picUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        artist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${artist.musicSize} 首歌曲 · ${artist.albumSize} 张专辑',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      onTap: () => Get.toNamed(
        AppRoutes.neteaseArtistDetail,
        arguments: artist,
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, NeteaseAlbumBrief album) {
    final theme = Theme.of(context);
    final date = album.publishTime > 0
        ? DateTime.fromMillisecondsSinceEpoch(album.publishTime)
        : null;
    final dateStr = date != null ? '${date.year}-${date.month.toString().padLeft(2, '0')}' : '';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: album.picUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: album.picUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.album, size: 20),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.album, size: 20),
              ),
      ),
      title: Text(
        album.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${album.artistName}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Get.toNamed(
        AppRoutes.neteaseAlbumDetail,
        arguments: album,
      ),
    );
  }

  Widget _buildPlaylistCard(
      BuildContext context, NeteasePlaylistBrief playlist) {
    final theme = Theme.of(context);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: playlist.coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.queue_music, size: 20),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.queue_music, size: 20),
              ),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatPlayCount(playlist.playCount),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      onTap: () => Get.toNamed(
        AppRoutes.neteasePlaylistDetail,
        arguments: playlist,
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿 播放';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万 播放';
    }
    return '$count 播放';
  }
}
