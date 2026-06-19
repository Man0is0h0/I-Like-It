import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeManager {
  // Singleton
  static final ThemeManager instance = ThemeManager._();
  ThemeManager._();

  final _storage = const FlutterSecureStorage();
  static const _keyTheme = 'theme_mode';

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  /// Initialize and load saved theme
  Future<void> initialize() async {
    try {
      final savedTheme = await _storage.read(key: _keyTheme);
      if (savedTheme != null) {
        themeModeNotifier.value = _parseThemeMode(savedTheme);
      }
    } catch (e) {
      print('ThemeManager: Error loading theme: $e');
    }
  }

  /// Update theme and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await _storage.write(key: _keyTheme, value: mode.toString());
  }

  ThemeMode _parseThemeMode(String value) {
    if (value == ThemeMode.light.toString()) return ThemeMode.light;
    if (value == ThemeMode.dark.toString()) return ThemeMode.dark;
    return ThemeMode.system;
  }
}
