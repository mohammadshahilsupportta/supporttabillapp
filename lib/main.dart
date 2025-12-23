import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/routes/app_routes.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handlers to prevent app crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log error but don't crash
    print('FlutterError: ${details.exception}');
    print('Stack: ${details.stack}');
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Uncaught error: $error');
    print('Stack: $stack');
    return true; // Prevent app crash
  };

  // Initialize services with error handling
  try {
    await GetStorage.init();
    await StorageService.initialize();
    await SupabaseService.initialize();
  } catch (e) {
    print('Error initializing services: $e');
    // Continue anyway - some services might still work
  }

  // Register AuthController globally - needed throughout app lifecycle
  try {
    Get.put<AuthController>(AuthController(), permanent: true);
  } catch (e) {
    print('Error registering AuthController: $e');
  }

  // Register ThemeController globally
  try {
    Get.put<ThemeController>(ThemeController(), permanent: true);
  } catch (e) {
    print('Error registering ThemeController: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme controller to observe theme changes
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Supportta Bill Book',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.routes,
      ),
    );
  }
}
