import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';

class AppColors {
  BuildContext context;

  AppColors._({required this.context});

  factory AppColors.of(BuildContext context) => AppColors._(context: context);

  static const transparent = Colors.transparent;
  static const white = Colors.white;
  static const black = Colors.black;

  static const lPrimary = Color(0xff394b61);
  static const lSecondary = Color(0xff5e92c4);
  static const lTernary = Color(0xffbddafa);
  static const lBg = Color(0xfff8f7f2);

  static const lTile1 = Color(0xfff0b9cc);
  static const lTile2 = Color(0xfffea300);
  static const lTile3 = Color(0xff3a88ae);
  static const lTile4 = Color(0xfffdd13b);
  static const lTile5 = Color(0xfff95e62);

  static const dPrimary = Color(0xff102A43);
  static const dSecondary = Color(0xff4a7ba4);
  static const dTernary = Color(0xff2b4c6f);
  static const dBg = Color(0xff121212);

  static const dTile1 = Color(0xffb24a61);
  static const dTile2 = Color(0xffc68400);
  static const dTile3 = Color(0xff2c6b86);
  static const dTile4 = Color(0xffd4a028);
  static const dTile5 = Color(0xffb13d41);

  static var blackGreyColor;

  get primaryColor => context.isDark ? white : lPrimary;
  get secondaryColor => context.isDark ? dSecondary : lSecondary;
  get ternaryColor => context.isDark ? dTernary : lTernary;
  get bgColor => context.isDark ? dBg : lBg;

  get tile1Color => context.isDark ? dTile1 : lTile1;
  get tile2Color => context.isDark ? dTile2 : lTile2;
  get tile3Color => context.isDark ? dTile3 : lTile3;
  get tile4Color => context.isDark ? dTile4 : lTile4;
  get tile5Color => context.isDark ? dTile5 : lTile5;
}
