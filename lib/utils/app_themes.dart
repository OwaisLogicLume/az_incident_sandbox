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

      // Light ColorScheme with theme colors
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: Colors.white,
        background: bgColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,  // Use theme color for AppBar
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,  // Light icons on colored AppBar
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
    // Dark mode uses fixed grayscale colors - no theme variants
    const primaryColor = Colors.white;
    final secondaryColor = Colors.grey[700]!;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xff000000), // Pure black background

      // Fixed grayscale ColorScheme for dark mode
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppColors.darkSurface,           // Cards, elevated surfaces
        surfaceContainerHighest: AppColors.darkSurfaceVariant, // Dialogs
        background: const Color(0xff000000),      // Pure black
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        outline: AppColors.darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff000000),  // Pure black AppBar for dark mode
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
