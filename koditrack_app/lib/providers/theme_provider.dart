import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

const _prefKey = 'theme_mode';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(ThemeMode initial) : _themeMode = initial;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  static Future<ThemeMode> loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void applyFromProfile(SettingsProvider settings) {
    final stored = settings.profile?.settings['theme_mode'] as String?;
    if (stored == null) return;
    final mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      SharedPreferences.getInstance().then(
        (p) => p.setString(_prefKey, stored),
      );
    }
  }

  Future<void> setThemeMode(
    ThemeMode mode, {
    SettingsProvider? settings,
  }) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_prefKey, value);

    if (settings != null) {
      await settings.updateProfile(settingsPatch: {'theme_mode': value});
    }
  }
}
