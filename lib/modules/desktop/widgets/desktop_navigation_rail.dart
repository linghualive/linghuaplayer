import 'package:flutter/material.dart';

/// Desktop navigation rail following Material 3 design
class DesktopNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  const DesktopNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minExtendedWidth: 168,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      backgroundColor: colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/logo.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '玲华音乐',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              )
            : Image.asset(
                'assets/logo.png',
                width: 28,
                height: 28,
              ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.play_circle_outline),
          selectedIcon: Icon(Icons.play_circle),
          label: Text('播放'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: Text('搜索'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.queue_music_outlined),
          selectedIcon: Icon(Icons.queue_music),
          label: Text('歌单'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('我的'),
        ),
      ],
    );
  }
}
