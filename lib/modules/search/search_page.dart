import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/search/search_video_model.dart';
import '../../data/services/local_playlist_service.dart';
import '../../shared/utils/app_toast.dart';
import '../../shared/widgets/animated_list_item.dart';
import '../../shared/widgets/create_fav_dialog.dart';
import '../../shared/widgets/empty_widget.dart';
import '../../shared/widgets/fav_panel.dart';
import '../player/player_controller.dart';
import 'search_controller.dart' as app;
import 'widgets/hot_search_list.dart';
import 'widgets/search_suggestion_list.dart';
import 'widgets/search_result_card.dart';
import 'widgets/search_skeleton.dart';

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            children: [
              ChoiceChip(
                label: const Text('GD音乐台'),
                selected:
                    controller.searchSource.value == 'gdstudio',
                onSelected: (_) =>
                    controller.switchSource(MusicSource.gdstudio),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('B站'),
                selected:
                    controller.searchSource.value == 'bilibili',
                onSelected: (_) =>
                    controller.switchSource(MusicSource.bilibili),
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
        _buildBatchActions(),
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
                return const SearchResultSkeleton();
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
                  return AnimatedListItem(
                    index: index,
                    child: _buildResultItem(context, index),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Obx(() {
            final count = controller.allResults
                .whereType<SearchVideoModel>()
                .length;
            return ActionChip(
              avatar: const Icon(Icons.playlist_add, size: 18),
              label: Text('收藏已加载的 $count 首到歌单'),
              onPressed: () {
                final tracks = controller.allResults
                    .whereType<SearchVideoModel>()
                    .toList();
                if (tracks.isEmpty) return;
                _showBatchFavDialog(tracks);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showBatchFavDialog(List<SearchVideoModel> tracks) {
    final context = Get.context;
    if (context == null) return;
    final service = Get.find<LocalPlaylistService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: _BatchFavPanel(tracks: tracks, service: service),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, int index) {
    final item = controller.allResults[index];

    if (item is SearchVideoModel) {
      if (item.isGdStudio) {
        return _buildSongCard(context, item);
      }
      return SearchResultCard(video: item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSongCard(BuildContext context, SearchVideoModel song) {
    final theme = Theme.of(context);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: song.pic.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: song.pic,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.music_note, size: 20, color: theme.colorScheme.outline),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.music_note, size: 20, color: theme.colorScheme.outline),
              ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.author +
            (song.description.isNotEmpty ? ' · ${song.description}' : '') +
            (song.duration.isNotEmpty ? ' · ${song.duration}' : ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.outline),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onSelected: (value) {
          final playerCtrl = Get.find<PlayerController>();
          switch (value) {
            case 'queue':
              playerCtrl.addToQueue(song);
              break;
            case 'fav':
              FavPanel.show(context, song);
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'queue', child: Text('添加到播放列表')),
          const PopupMenuItem(value: 'fav', child: Text('收藏到歌单')),
        ],
      ),
      onTap: () {
        final playerCtrl = Get.find<PlayerController>();
        playerCtrl.playFromSearch(song);
      },
    );
  }
}

class _BatchFavPanel extends StatefulWidget {
  final List<SearchVideoModel> tracks;
  final LocalPlaylistService service;

  const _BatchFavPanel({required this.tracks, required this.service});

  @override
  State<_BatchFavPanel> createState() => _BatchFavPanelState();
}

class _BatchFavPanelState extends State<_BatchFavPanel> {
  late Map<String, bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = {for (final p in widget.service.playlists) p.id: false};
  }

  void _onConfirm() {
    int added = 0;
    for (final p in widget.service.playlists) {
      if (_checked[p.id] != true) continue;
      for (final track in widget.tracks) {
        final alreadyIn =
            p.tracks.any((t) => t.uniqueId == track.uniqueId);
        if (!alreadyIn) {
          widget.service.addTrack(p.id, track);
          added++;
        }
      }
    }
    Navigator.pop(context);
    if (added > 0) {
      AppToast.success('已添加 $added 首歌曲');
    } else {
      AppToast.show('歌曲已在所选歌单中');
    }
  }

  void _onCreated() {
    setState(() {
      for (final p in widget.service.playlists) {
        _checked.putIfAbsent(p.id, () => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final playlists = widget.service.playlists.toList();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  '收藏全部 (${widget.tracks.length} 首)',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    CreateFavDialog.show(context, onCreated: _onCreated);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建'),
                ),
              ],
            ),
          ),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无歌单，请先新建一个'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return CheckboxListTile(
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.trackCount} 首'),
                    value: _checked[playlist.id] ?? false,
                    onChanged: (val) {
                      setState(() => _checked[playlist.id] = val ?? false);
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _onConfirm,
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
