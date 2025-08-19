import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// for getting theme instance
extension ThemeExtensions on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ThemeData get theme => Theme.of(this);

  AppColors get appColors => AppColors.of(this);
}
