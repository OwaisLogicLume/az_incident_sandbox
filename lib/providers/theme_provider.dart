import 'package:flutter/material.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';

enum AppTheme {
  blue,
  desertSunset,
  terracotta,
  adobe,
  cactusGreen,
}

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.desertSunset;

  AppTheme get currentTheme => _currentTheme;

  String get themeName {
    switch (_currentTheme) {
      case AppTheme.blue:
        return 'Ocean Blue';
      case AppTheme.desertSunset:
        return 'Desert Sunset';
      case AppTheme.terracotta:
        return 'Terracotta';
      case AppTheme.adobe:
        return 'Adobe';
      case AppTheme.cactusGreen:
        return 'Cactus Green';
    }
  }

  Future<void> loadTheme() async {
    final savedThemeIndex = await SharedPrefs.instance.getThemeIndex();
    if (savedThemeIndex != null && savedThemeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[savedThemeIndex];
      notifyListeners();
    }
  }

  Future<void> cycleTheme() async {
    final currentIndex = _currentTheme.index;
    final nextIndex = (currentIndex + 1) % AppTheme.values.length;
    _currentTheme = AppTheme.values[nextIndex];

    await SharedPrefs.instance.setThemeIndex(nextIndex);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await SharedPrefs.instance.setThemeIndex(theme.index);
    notifyListeners();
  }
}
