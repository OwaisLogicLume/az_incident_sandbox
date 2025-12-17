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
    // Dark mode now uses theme-specific colors (muted/darker variants)
    Color primaryColor;
    Color secondaryColor;
    Color ternaryColor;
    Color bgColor;
    Color surfaceColor;

    switch (appTheme) {
      case AppTheme.blue:
        primaryColor = AppColors.blueDPrimary;
        secondaryColor = AppColors.blueDSecondary;
        ternaryColor = AppColors.blueDTernary;
        bgColor = AppColors.blueDBg;
        surfaceColor = AppColors.blueDSurface;
        break;
      case AppTheme.desertSunset:
        primaryColor = AppColors.sunsetDPrimary;
        secondaryColor = AppColors.sunsetDSecondary;
        ternaryColor = AppColors.sunsetDTernary;
        bgColor = AppColors.sunsetDBg;
        surfaceColor = AppColors.sunsetDSurface;
        break;
      case AppTheme.terracotta:
        primaryColor = AppColors.terracottaDPrimary;
        secondaryColor = AppColors.terracottaDSecondary;
        ternaryColor = AppColors.terracottaDTernary;
        bgColor = AppColors.terracottaDBg;
        surfaceColor = AppColors.terracottaDSurface;
        break;
      case AppTheme.adobe:
        primaryColor = AppColors.adobeDPrimary;
        secondaryColor = AppColors.adobeDSecondary;
        ternaryColor = AppColors.adobeDTernary;
        bgColor = AppColors.adobeDBg;
        surfaceColor = AppColors.adobeDSurface;
        break;
      case AppTheme.cactusGreen:
        primaryColor = AppColors.greenDPrimary;
        secondaryColor = AppColors.greenDSecondary;
        ternaryColor = AppColors.greenDTernary;
        bgColor = AppColors.greenDBg;
        surfaceColor = AppColors.greenDSurface;
        break;
    }

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor, // Theme-tinted dark background

      // Theme-specific ColorScheme for dark mode
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: ternaryColor,
        surface: surfaceColor,                    // Theme-tinted cards/surfaces
        surfaceContainerHighest: surfaceColor,    // Theme-tinted dialogs
        background: bgColor,                      // Theme-tinted background
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        outline: AppColors.darkBorder,            // Keep grayscale borders
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff000000),  // Keep pure black AppBar
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
