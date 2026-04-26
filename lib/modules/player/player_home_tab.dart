import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../shared/utils/platform_utils.dart';
import '../../shared/widgets/fav_panel.dart';
import '../home/widgets/mode_drawer.dart';
import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_lyrics.dart';
import 'widgets/swipeable_player_body.dart';

class PlayerHomeTab extends StatefulWidget {
  const PlayerHomeTab({super.key});

  @override
  State<PlayerHomeTab> createState() => _PlayerHomeTabState();
}

class _PlayerHomeTabState extends State<PlayerHomeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawerCtrl;
  late final Animation<double> _drawerSlide;
  bool _drawerOpen = false;

  static const _drawerWidthFraction = 0.75;

  @override
  void initState() {
    super.initState();
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _drawerSlide = CurvedAnimation(
      parent: _drawerCtrl,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerOpen) {
      _drawerCtrl.reverse();
    } else {
      _drawerCtrl.forward();
    }
    _drawerOpen = !_drawerOpen;
  }

  void _closeDrawer() {
    if (_drawerOpen) {
      _drawerCtrl.reverse();
      _drawerOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop) return _buildDesktopScaffold(context);
    return _buildMobileSlideDrawer(context);
  }

  Widget _buildMobileSlideDrawer(BuildContext context) {
    final playerCtrl = Get.find<PlayerController>();
    final drawerWidth =
        MediaQuery.of(context).size.width * _drawerWidthFraction;

    final drawerChild = RepaintBoundary(
      child: SizedBox(
        width: drawerWidth,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: ModeDrawer(onClose: _closeDrawer),
        ),
      ),
    );

    final mainChild = RepaintBoundary(
      child: _buildMainScaffold(context, playerCtrl),
    );

    return AnimatedBuilder(
      animation: _drawerSlide,
      child: mainChild,
      builder: (context, cachedMain) {
        final t = _drawerSlide.value;
        final mainTx = t * drawerWidth;
        final drawerTx = -drawerWidth * 0.3 * (1 - t);

        return Stack(
          children: [
            Transform.translate(
              offset: Offset(drawerTx, 0),
              child: drawerChild,
            ),
            Transform.translate(
              offset: Offset(mainTx, 0),
              child: GestureDetector(
                onTap: _drawerOpen ? _closeDrawer : null,
                onHorizontalDragUpdate: _handleDrag,
                onHorizontalDragEnd: _handleDragEnd,
                child: AbsorbPointer(
                  absorbing: _drawerOpen && t > 0.5,
                  child: cachedMain!,
                ),
              ),
            ),
            if (t > 0)
              Positioned(
                left: mainTx - 10,
                top: 0,
                bottom: 0,
                width: 10,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.04 * t),
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
  }

  void _handleDrag(DragUpdateDetails details) {
    final drawerWidth =
        MediaQuery.of(context).size.width * _drawerWidthFraction;
    final delta = details.primaryDelta ?? 0;
    _drawerCtrl.value += delta / drawerWidth;
  }

  void _handleDragEnd(DragEndDetails details) {
    final drawerWidth =
        MediaQuery.of(context).size.width * _drawerWidthFraction;
    final velocity = (details.primaryVelocity ?? 0) / drawerWidth;

    final target =
        (velocity > 1.0 || (_drawerCtrl.value > 0.5 && velocity >= 0))
            ? 1.0
            : 0.0;
    _drawerOpen = target == 1.0;

    final distance = (_drawerCtrl.value - target).abs();
    final ms = (distance * 320).toInt().clamp(80, 320);
    _drawerCtrl.animateTo(
      target,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildMainScaffold(BuildContext context, PlayerController playerCtrl) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: '模式',
          onPressed: _toggleDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索音乐',
            onPressed: () => Get.toNamed(AppRoutes.search),
          ),
          ..._buildActionWidgets(context, playerCtrl),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBackground(
        context,
        playerCtrl: playerCtrl,
        child: SafeArea(
          child: _buildMobilePlayerUI(context, playerCtrl),
        ),
      ),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    final playerCtrl = Get.find<PlayerController>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _buildBackground(
        context,
        playerCtrl: playerCtrl,
        child: SafeArea(
          child: Row(
            children: [
              _buildDesktopSidebar(context),
              Expanded(
                child: Column(
                  children: [
                    _buildDesktopTopBar(context, playerCtrl),
                    Expanded(
                        child: _buildDesktopPlayerUI(context, playerCtrl)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ModeDrawer(onClose: () {}),
    );
  }

  Widget _buildDesktopTopBar(
      BuildContext context, PlayerController playerCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索音乐',
            onPressed: () => Get.toNamed(AppRoutes.search),
          ),
          ..._buildActionWidgets(context, playerCtrl),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context,
      {required Widget child, required PlayerController playerCtrl}) {
    return Obx(() {
      final dynamicColor = playerCtrl.coverColor.value;
      final topColor = dynamicColor?.withValues(alpha: 0.6) ??
          Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.4);
      final midColor =
          (dynamicColor ?? Theme.of(context).colorScheme.primaryContainer)
              .withValues(alpha: 0.15);
      final bottomColor = Theme.of(context).colorScheme.surface;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, midColor, bottomColor],
            stops: const [0.0, 0.5, 1.0],
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

  Widget _buildMobilePlayerUI(
      BuildContext context, PlayerController playerCtrl) {
    return SwipeablePlayerBody(
      buildArtworkArea: () => _buildArtworkArea(playerCtrl),
      controlsArea: const PlayerControls(),
    );
  }

  Widget _buildDesktopPlayerUI(
      BuildContext context, PlayerController playerCtrl) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildArtworkArea(playerCtrl),
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const PlayerControls(),
                ),
              ),
            ],
          ),
        ),
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
