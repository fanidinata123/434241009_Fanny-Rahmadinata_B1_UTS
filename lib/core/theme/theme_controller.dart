import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller sederhana untuk mengelola ThemeMode aplikasi secara global.
///
/// Menggunakan ValueNotifier supaya MaterialApp bisa langsung
/// rebuild ulang (via ValueListenableBuilder) setiap kali mode
/// tema berubah, tanpa perlu state management tambahan (Bloc/Provider)
/// khusus untuk ini.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static const _prefsKey = 'theme_mode';

  /// Dipanggil sekali saat aplikasi pertama kali dijalankan (sebelum
  /// runApp), untuk memuat preferensi tema yang tersimpan sebelumnya.
  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    switch (saved) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'system':
        themeMode.value = ThemeMode.system;
        break;
      default:
        themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Toggle cepat antara light <-> dark (dipakai misal di Profile/Settings
  /// sebagai switch sederhana).
  static Future<void> toggleLightDark() async {
    final next = themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(next);
  }
}