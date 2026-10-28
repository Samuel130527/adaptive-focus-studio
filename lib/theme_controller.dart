
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.light);

const String darkModeKey = 'darkModeEnabled';

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  appThemeMode.value =
      prefs.getBool(darkModeKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
}

Future<void> saveTheme(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(darkModeKey, isDark);
  appThemeMode.value =
      isDark ? ThemeMode.dark : ThemeMode.light;
}
