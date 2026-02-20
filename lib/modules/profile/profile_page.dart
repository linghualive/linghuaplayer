import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../shared/widgets/cached_image.dart';
import '../home/home_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Linked accounts card
            _buildAccountsCard(context, controller),
            const SizedBox(height: 12),

            // Play history & favorites
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('播放历史'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(AppRoutes.watchHistory),
              ),
            ),
            const SizedBox(height: 12),

            // Settings
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(AppRoutes.settings),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAccountsCard(
      BuildContext context, HomeController controller) {
    final theme = Theme.of(context);
    final hasBili = controller.isLoggedIn.value;
    final hasNetease = controller.isNeteaseLoggedIn.value;
    final hasQq = controller.isQqMusicLoggedIn.value;
    final hasAny = hasBili || hasNetease || hasQq;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '已关联账号',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                '暂无关联账号，可在歌单页面导入时登录',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),

          // Bilibili
          if (hasBili) ...[
            _buildAccountTile(
              context,
              icon: Icons.smart_display,
              platform: '哔哩哔哩',
              name: controller.userInfo.value?.uname ?? '用户',
              avatarUrl: controller.userInfo.value?.face,
              color: const Color(0xFFFB7299),
              onLogout: () => controller.logout(),
            ),
          ],

          // Netease
          if (hasNetease) ...[
            if (hasBili) const Divider(height: 1, indent: 56),
            _buildAccountTile(
              context,
              icon: Icons.cloud,
              platform: '网易云',
              name: controller.neteaseUserInfo.value?.nickname ?? '网易云用户',
              avatarUrl: controller.neteaseUserInfo.value?.avatarUrl,
              color: const Color(0xFFE60026),
              onLogout: () => controller.logoutNetease(),
            ),
          ],

          // QQ Music
          if (hasQq) ...[
            if (hasBili || hasNetease) const Divider(height: 1, indent: 56),
            _buildAccountTile(
              context,
              icon: Icons.queue_music,
              platform: 'QQ音乐',
              name: controller.qqMusicUserInfo.value?.nickname ?? 'QQ音乐用户',
              avatarUrl: controller.qqMusicUserInfo.value?.avatarUrl,
              color: const Color(0xFF31C27C),
              onLogout: () => controller.logoutQqMusic(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required IconData icon,
    required String platform,
    required String name,
    String? avatarUrl,
    required Color color,
    required VoidCallback onLogout,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipOval(
              child: CachedImage(imageUrl: avatarUrl, width: 36, height: 36),
            )
          : CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, size: 18, color: color),
            ),
      title: Row(
        children: [
          Flexible(
            child:
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              platform,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      trailing: TextButton(
        onPressed: onLogout,
        child: Text(
          '退出',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
        ),
      ),
    );
  }
}
