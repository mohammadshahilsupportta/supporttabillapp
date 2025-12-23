import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/storage_service.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final savedTheme = StorageService.instance.themeMode;
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          themeMode.value = ThemeMode.dark;
          break;
        case 'system':
          themeMode.value = ThemeMode.system;
          break;
        default:
          themeMode.value = ThemeMode.light;
      }
    } else {
      // Default to light theme if nothing is saved
      themeMode.value = ThemeMode.light;
      _saveThemeMode('light');
    }
    Get.changeThemeMode(themeMode.value);
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _saveThemeMode(_themeModeToString(mode));
  }

  void _saveThemeMode(String mode) {
    StorageService.instance.themeMode = mode;
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  bool get isDarkMode => Get.isDarkMode;
  bool get isLightMode => !Get.isDarkMode;
}

