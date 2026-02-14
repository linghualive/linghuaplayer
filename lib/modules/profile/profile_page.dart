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
        title: const Text('Profile'),
      ),
      body: Obx(() {
        if (!controller.isLoggedIn.value) {
          return _buildLoggedOut(context);
        }
        return _buildLoggedIn(context, controller);
      }),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Not logged in',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.login),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedIn(BuildContext context, HomeController controller) {
    final user = controller.userInfo.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: ClipOval(
            child: CachedImage(
              imageUrl: user?.face,
              width: 80,
              height: 80,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user?.uname ?? 'User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Center(
          child: Text(
            'Lv.${user?.currentLevel ?? 0}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('UID: ${user?.mid ?? ''}'),
        ),
        if (user?.isVip ?? false)
          const ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('VIP Member'),
          ),
        const Divider(),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              await controller.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      ],
    );
  }
}
