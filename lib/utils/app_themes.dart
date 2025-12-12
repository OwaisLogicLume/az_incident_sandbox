import 'package:az_incident_alert/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData getLightTheme(AppTheme appTheme) {
    Color primaryColor;
    Color bgColor;

    switch (appTheme) {
      case AppTheme.blue:
        primaryColor = AppColors.blueLPrimary;
        bgColor = AppColors.blueLBg;
        break;
      case AppTheme.desertSunset:
        primaryColor = AppColors.sunsetLPrimary;
        bgColor = AppColors.sunsetLBg;
        break;
      case AppTheme.terracotta:
        primaryColor = AppColors.terracottaLPrimary;
        bgColor = AppColors.terracottaLBg;
        break;
      case AppTheme.adobe:
        primaryColor = AppColors.adobeLPrimary;
        bgColor = AppColors.adobeLBg;
        break;
      case AppTheme.cactusGreen:
        primaryColor = AppColors.greenLPrimary;
        bgColor = AppColors.greenLBg;
        break;
    }

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData getDarkTheme(AppTheme appTheme) {
    // All dark themes use the same dark background
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.blueDBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.white10,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Legacy support
  static ThemeData get lightTheme => getLightTheme(AppTheme.blue);
  static ThemeData get darkTheme => getDarkTheme(AppTheme.blue);
}
