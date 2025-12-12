import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/screens/subscription_screen.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  final bool isRecommended;
  final bool isPurchasing;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isRecommended = false,
    this.isPurchasing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isPurchasing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(top: isRecommended ? 32 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card content
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.appColors.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, isRecommended ? 40 : 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.title,
                        style: textStyle22Bold.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!isPurchasing)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.price,
                    style: textStyle14.copyWith(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (plan.subtitle != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.appColors.secondaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.appColors.secondaryColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: context.appColors.secondaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            plan.subtitle!,
                            style: textStyle12.copyWith(
                              color: context.appColors.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isPurchasing) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Recommended badge
            if (isRecommended)
              Positioned(
                top: -1,
                left: -1,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appColors.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'MOST POPULAR',
                      style: textStyle12.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
