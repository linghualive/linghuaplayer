import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_controller.dart';
import 'core/http/http_client.dart';
import 'core/http/netease_http_client.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize storage
  await GetStorage.init();
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);

  // Initialize HTTP clients
  await HttpClient.instance.init();
  NeteaseHttpClient.instance.init();

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

          if (themeCtrl.dynamicColor.value &&
              lightDynamic != null &&
              darkDynamic != null) {
            lightTheme = AppTheme.lightThemeFromScheme(lightDynamic.harmonized());
            darkTheme = AppTheme.darkThemeFromScheme(darkDynamic.harmonized());
          } else {
            final seed = themeCtrl.seedColor;
            lightTheme = AppTheme.lightTheme(seed);
            darkTheme = AppTheme.darkTheme(seed);
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
