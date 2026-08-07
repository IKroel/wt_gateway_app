// Preferencia de tema claro/oscuro (persistida).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore {
  static SharedPreferences? _p;
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  static Future<void> init() async {
    _p ??= await SharedPreferences.getInstance();
    final v = _p!.getString('theme_mode');
    mode.value = (v == 'light') ? ThemeMode.light : ThemeMode.dark;
  }

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    await _p?.setString('theme_mode', dark ? 'dark' : 'light');
  }
}
