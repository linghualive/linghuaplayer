import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/desktop_theme.dart';
import 'app/theme/theme_controller.dart';
import 'core/http/deepseek_http_client.dart';
import 'core/http/http_client.dart';
import 'core/http/netease_http_client.dart';
import 'core/http/qqmusic_http_client.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Desktop window configuration
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1000, 600),
      center: true,
      title: 'FlameKit',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize storage
  await GetStorage.init();
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);

  // Initialize HTTP clients
  await HttpClient.instance.init();
  await NeteaseHttpClient.instance.init();
  await QqMusicHttpClient.instance.init();

  // Restore QQ Music login state from storage
  final qqMusicUin = storageService.qqMusicUin;
  final qqMusicPSkey = storageService.qqMusicPSkey;
  if (qqMusicUin != null &&
      qqMusicUin.isNotEmpty &&
      storageService.isQqMusicLoggedIn) {
    QqMusicHttpClient.instance.updateLoginUin(qqMusicUin);
    if (qqMusicPSkey != null && qqMusicPSkey.isNotEmpty) {
      QqMusicHttpClient.instance.updateGtk(qqMusicPSkey);
    }
  }

  // Initialize DeepSeek HTTP client if API key exists
  final deepseekKey = storageService.deepseekApiKey;
  if (deepseekKey != null && deepseekKey.isNotEmpty) {
    DeepSeekHttpClient.instance.init(deepseekKey);
  }

  // Initialize theme controller
  Get.put(ThemeController(), permanent: true);

  runApp(const FlameKitApp());
}

class FlameKitApp extends StatelessWidget {
  const FlameKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Obx(() {
          ThemeData lightTheme;
          ThemeData darkTheme;

          // Check if running on desktop
          final isDesktop =
              Platform.isWindows || Platform.isMacOS || Platform.isLinux;

          if (themeCtrl.dynamicColor.value &&
              lightDynamic != null &&
              darkDynamic != null) {
            if (isDesktop) {
              lightTheme = DesktopTheme.createDesktopTheme(
                colorScheme: lightDynamic.harmonized(),
              );
              darkTheme = DesktopTheme.createDesktopTheme(
                colorScheme: darkDynamic.harmonized(),
              );
            } else {
              lightTheme =
                  AppTheme.lightThemeFromScheme(lightDynamic.harmonized());
              darkTheme =
                  AppTheme.darkThemeFromScheme(darkDynamic.harmonized());
            }
          } else {
            final seed = themeCtrl.seedColor;
            if (isDesktop) {
              final lightColorScheme = ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              );
              final darkColorScheme = ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              );
              lightTheme = DesktopTheme.createDesktopTheme(
                colorScheme: lightColorScheme,
              );
              darkTheme = DesktopTheme.createDesktopTheme(
                colorScheme: darkColorScheme,
              );
            } else {
              lightTheme = AppTheme.lightTheme(seed);
              darkTheme = AppTheme.darkTheme(seed);
            }
          }

          return GetMaterialApp(
            title: 'FlameKit',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeCtrl.themeModeEnum,
            initialRoute: AppRoutes.splash,
            getPages: AppPages.pages,
            initialBinding: InitialBinding(),
          );
        });
      },
    );
  }
}
