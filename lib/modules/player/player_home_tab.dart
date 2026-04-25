import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/utils/platform_utils.dart';
import '../../shared/widgets/fav_panel.dart';
import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_lyrics.dart';
import 'widgets/swipeable_player_body.dart';

class PlayerHomeTab extends StatelessWidget {
  const PlayerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.find<PlayerController>();
    final isDesktop = PlatformUtils.isDesktop;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                ..._buildActionWidgets(context, playerCtrl),
                const SizedBox(width: 4),
              ],
            ),
      body: _buildBackground(
        context,
        playerCtrl: playerCtrl,
        child: SafeArea(
          child: isDesktop
              ? Column(
                  children: [
                    _buildDesktopTopBar(context, playerCtrl),
                    Expanded(child: _buildContent(context, playerCtrl)),
                  ],
                )
              : _buildContent(context, playerCtrl),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(
      BuildContext context, PlayerController playerCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Spacer(),
          ..._buildActionWidgets(context, playerCtrl),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context,
      {required Widget child, required PlayerController playerCtrl}) {
    return Obx(() {
      final dynamicColor = playerCtrl.coverColor.value;
      final topColor = dynamicColor?.withValues(alpha: 0.35) ??
          Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3);
      final bottomColor = Theme.of(context).colorScheme.surface;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, bottomColor],
          ),
        ),
        child: child,
      );
    });
  }

  List<Widget> _buildActionWidgets(
      BuildContext context, PlayerController playerCtrl) {
    return [
      Obx(() {
        final video = playerCtrl.currentVideo.value;
        if (video == null) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.favorite_border),
          tooltip: '收藏到歌单',
          onPressed: () => FavPanel.show(context, video),
        );
      }),
    ];
  }

  Widget _buildContent(BuildContext context, PlayerController playerCtrl) {
    return _buildPlayerUI(context, playerCtrl);
  }

  Widget _buildPlayerUI(BuildContext context, PlayerController playerCtrl) {
    if (PlatformUtils.isDesktop) {
      return _buildDesktopPlayerUI(context, playerCtrl);
    }
    return _buildMobilePlayerUI(context, playerCtrl);
  }

  Widget _buildMobilePlayerUI(
      BuildContext context, PlayerController playerCtrl) {
    return SwipeablePlayerBody(
      buildArtworkArea: () => _buildArtworkArea(playerCtrl),
      controlsArea: const PlayerControls(),
    );
  }

  Widget _buildDesktopPlayerUI(
      BuildContext context, PlayerController playerCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _buildArtworkArea(playerCtrl),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const PlayerControls(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkArea(PlayerController playerCtrl) {
    return Obx(() {
      return GestureDetector(
        onTap: () => playerCtrl.toggleLyricsView(),
        child: playerCtrl.showLyrics.value
            ? const PlayerLyrics()
            : const PlayerArtwork(),
      );
    });
  }
}
