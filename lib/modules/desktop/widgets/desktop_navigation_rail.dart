import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/home_controller.dart';

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
    final homeController = Get.find<HomeController>();

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      backgroundColor: colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FlameKit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              )
            : Icon(
                Icons.local_fire_department_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extended) ...[
              // Profile section for extended rail
              Obx(() {
                final isLoggedIn = homeController.authService.isLoggedIn.value;
                if (isLoggedIn) {
                  return InkWell(
                    onTap: () => Get.toNamed('/profile'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              homeController.authService.currentUser.value?.uname.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(color: colorScheme.onPrimaryContainer),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              homeController.authService.currentUser.value?.uname ?? '用户',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () => Get.toNamed('/login'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_circle_outlined, color: colorScheme.onSurfaceVariant, size: 40),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text('登录'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
              const SizedBox(height: 16),
            ],
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed('/settings'),
              tooltip: '设置',
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.music_note_outlined),
          selectedIcon: Icon(Icons.music_note),
          label: Text('音乐'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.video_library_outlined),
          selectedIcon: Icon(Icons.video_library),
          label: Text('视频'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: Text('发现'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: Text('歌单'),
        ),
      ],
    );
  }
}