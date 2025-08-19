import 'package:flutter/material.dart';

extension ThemeModeExt on String {
  ThemeMode get toTheme => switch (this) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => throw Exception('not a valid theme type: $this'),
      };
}
