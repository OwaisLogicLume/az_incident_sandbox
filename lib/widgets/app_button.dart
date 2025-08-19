import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonColorType { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.colorType = AppButtonColorType.primary,
    this.isLoading = false,
    this.elevation,
    this.radius = 16,
    this.icon,
    this.textStyle,
  });

  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final AppButtonColorType? colorType;
  final bool? isLoading;
  final double? radius;
  final double? elevation;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        backgroundColor: backgroundColor ??
            (colorType == AppButtonColorType.primary
                ? context.appColors.primaryColor
                : AppColors.white),
        foregroundColor: foregroundColor ??
            (colorType == AppButtonColorType.primary
                ? AppColors.white
                : context.appColors.primaryColor),
        fixedSize: Size.fromHeight(60.h),
      ),
      icon: isLoading ?? false ? Container() : icon ?? Container(),
      label: isLoading ?? false
          ? SizedBox(
              height: 25.h,
              width: 25.w,
              child: CircularProgressIndicator(
                strokeWidth: 3.r,
                color: foregroundColor ??
                    (colorType == AppButtonColorType.primary
                        ? AppColors.white
                        : context.appColors.primaryColor),
              ),
            )
          : Text(
              text,
              style: textStyle16SemiBold.copyWith(
                color: colorType == AppButtonColorType.primary
                    ? AppColors.white
                    : context.appColors.primaryColor,
              ),
            ),
    );
  }
}
