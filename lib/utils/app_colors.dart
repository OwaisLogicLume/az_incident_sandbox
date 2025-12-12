import 'package:az_incident_alert/providers/theme_provider.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppColors {
  BuildContext context;

  AppColors._({required this.context});

  factory AppColors.of(BuildContext context) => AppColors._(context: context);

  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;

  // Theme 1: Blue (Original)
  static const blueLPrimary = Color(0xff394b61);
  static const blueLSecondary = Color(0xff5e92c4);
  static const blueLTernary = Color(0xffbddafa);
  static const blueLBg = Color(0xfff8f7f2);

  static const blueDPrimary = Color(0xff102A43);
  static const blueDSecondary = Color(0xff4a7ba4);
  static const blueDTernary = Color(0xff2b4c6f);
  static const blueDBg = Color(0xff121212);

  // Theme 2: Desert Sunset
  static const sunsetLPrimary = Color(0xffE8833A);
  static const sunsetLSecondary = Color(0xffF4B942);
  static const sunsetLTernary = Color(0xffFFD699);
  static const sunsetLBg = Color(0xffFFF8F0);

  static const sunsetDPrimary = Color(0xffD4662A);
  static const sunsetDSecondary = Color(0xffE89A3A);
  static const sunsetDTernary = Color(0xff5C2E1A);
  static const sunsetDBg = Color(0xff121212);

  // Theme 3: Terracotta
  static const terracottaLPrimary = Color(0xffC85A3E);
  static const terracottaLSecondary = Color(0xffE89A73);
  static const terracottaLTernary = Color(0xffF4C4A8);
  static const terracottaLBg = Color(0xffFDF6F0);

  static const terracottaDPrimary = Color(0xff9B3922);
  static const terracottaDSecondary = Color(0xffC85A3E);
  static const terracottaDTernary = Color(0xff6B2818);
  static const terracottaDBg = Color(0xff121212);

  // Theme 4: Adobe
  static const adobeLPrimary = Color(0xffD4A574);
  static const adobeLSecondary = Color(0xffB88C5D);
  static const adobeLTernary = Color(0xffE8C9A0);
  static const adobeLBg = Color(0xffFAF5EE);

  static const adobeDPrimary = Color(0xff8B6F47);
  static const adobeDSecondary = Color(0xffB88C5D);
  static const adobeDTernary = Color(0xff5C4A33);
  static const adobeDBg = Color(0xff121212);

  // Theme 5: Cactus Green
  static const greenLPrimary = Color(0xff7B9337);
  static const greenLSecondary = Color(0xff5B7521);
  static const greenLTernary = Color(0xffA8C46F);
  static const greenLBg = Color(0xffF5F8F0);

  static const greenDPrimary = Color(0xff5B7521);
  static const greenDSecondary = Color(0xff7B9337);
  static const greenDTernary = Color(0xff445716);
  static const greenDBg = Color(0xff121212);

  // Tile colors (same for all themes)
  static const lTile1 = Color(0xfff0b9cc);
  static const lTile2 = Color(0xfffea300);
  static const lTile3 = Color(0xff3a88ae);
  static const lTile4 = Color(0xfffdd13b);
  static const lTile5 = Color(0xfff95e62);

  static const dTile1 = Color(0xffb24a61);
  static const dTile2 = Color(0xffc68400);
  static const dTile3 = Color(0xff2c6b86);
  static const dTile4 = Color(0xffd4a028);
  static const dTile5 = Color(0xffb13d41);

  // Legacy static colors for backward compatibility
  static const lPrimary = blueLPrimary;
  static const lSecondary = blueLSecondary;
  static const lTernary = blueLTernary;
  static const lBg = blueLBg;

  static const dPrimary = blueDPrimary;
  static const dSecondary = blueDSecondary;
  static const dTernary = blueDTernary;
  static const dBg = blueDBg;

  static var blackGreyColor;

  // Get colors based on current theme
  Color get primaryColor {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = context.isDark;

    switch (theme) {
      case AppTheme.blue:
        return isDark ? white : blueLPrimary;
      case AppTheme.desertSunset:
        return isDark ? white : sunsetLPrimary;
      case AppTheme.terracotta:
        return isDark ? white : terracottaLPrimary;
      case AppTheme.adobe:
        return isDark ? white : adobeLPrimary;
      case AppTheme.cactusGreen:
        return isDark ? white : greenLPrimary;
    }
  }

  Color get secondaryColor {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = context.isDark;

    switch (theme) {
      case AppTheme.blue:
        return isDark ? blueDSecondary : blueLSecondary;
      case AppTheme.desertSunset:
        return isDark ? sunsetDSecondary : sunsetLSecondary;
      case AppTheme.terracotta:
        return isDark ? terracottaDSecondary : terracottaLSecondary;
      case AppTheme.adobe:
        return isDark ? adobeDSecondary : adobeLSecondary;
      case AppTheme.cactusGreen:
        return isDark ? greenDSecondary : greenLSecondary;
    }
  }

  Color get ternaryColor {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = context.isDark;

    switch (theme) {
      case AppTheme.blue:
        return isDark ? blueDTernary : blueLTernary;
      case AppTheme.desertSunset:
        return isDark ? sunsetDTernary : sunsetLTernary;
      case AppTheme.terracotta:
        return isDark ? terracottaDTernary : terracottaLTernary;
      case AppTheme.adobe:
        return isDark ? adobeDTernary : adobeLTernary;
      case AppTheme.cactusGreen:
        return isDark ? greenDTernary : greenLTernary;
    }
  }

  Color get bgColor {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = context.isDark;

    switch (theme) {
      case AppTheme.blue:
        return isDark ? blueDBg : blueLBg;
      case AppTheme.desertSunset:
        return isDark ? sunsetDBg : sunsetLBg;
      case AppTheme.terracotta:
        return isDark ? terracottaDBg : terracottaLBg;
      case AppTheme.adobe:
        return isDark ? adobeDBg : adobeLBg;
      case AppTheme.cactusGreen:
        return isDark ? greenDBg : greenLBg;
    }
  }

  get tile1Color => context.isDark ? dTile1 : lTile1;
  get tile2Color => context.isDark ? dTile2 : lTile2;
  get tile3Color => context.isDark ? dTile3 : lTile3;
  get tile4Color => context.isDark ? dTile4 : lTile4;
  get tile5Color => context.isDark ? dTile5 : lTile5;
}
