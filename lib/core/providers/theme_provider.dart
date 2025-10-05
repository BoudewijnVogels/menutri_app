import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 ThemeNotifier met support voor light/dark/system
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode');

    if (themeString != null) {
      switch (themeString) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    }
  }

  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'light');
  }

  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'dark');
  }

  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', 'system');
  }

  // backwards compatibility met toggle
  Future<void> toggleTheme(bool isDark) async {
    if (isDark) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
}

// Provider voor de hele app
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
