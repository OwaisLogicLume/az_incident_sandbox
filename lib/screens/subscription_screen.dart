import 'dart:developer';

import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/services/in_app_purchase_helper.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_button.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/subscription_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final List<Plan> plans;
    InAppPurchaseHelper _inAppPurchaseHelper = InAppPurchaseHelper();

  String buttonText = 'Start 3 day free trial';
  bool trialEnded = false;

  @override
  void initState() {
    super.initState();
    
    plans = _getStaticPlans();
    _checkInAppPurchaseAvailability();
    // checkTrialStatus(); // Uncomment if you want to use it
  }
   bool _isLoading = true;
    void _checkInAppPurchaseAvailability() async {
    bool isAvailable = await _inAppPurchaseHelper.checkAvailability();

    if (isAvailable) {
      await _inAppPurchaseHelper.startListening();

      log("=================In-app purchases are available.");
      await _inAppPurchaseHelper.initializeProducts();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      log("==========In-app purchases are not available.");
    }
  }

  List<Plan> _getStaticPlans() {
    return [
      Plan(
        title: 'YEARLY',
        price: '\$6.67/months',
        isSelected: true,
      ),
      Plan(
        title: 'MONTHLY',
        price: '\$8.99/months',
        isSelected: false,
      ),
      Plan(
        title: 'WEEKLY',
        price: '\$3.99',
        isSelected: false,
      ),
    ];
  }

  void selectPlan(int index) {
    setState(() {
      for (int i = 0; i < plans.length; i++) {
        plans[i].isSelected = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          context.pushNamed(AppRoute.tabs.name);
                        },
                        icon: Icon(Icons.close_outlined),
                      )),
                  Text(
                    'Get Premium',
                    style: textStyle14Bold.copyWith(fontSize: 24.w),
                  ),
                  8.verticalSpace,
                  Text(
                    'Unlock the power of mobile tool and\nenjoy digital experience like never before!',
                    textAlign: TextAlign.center,
                    style: textStyle16SemiBold.copyWith(fontSize: 12.sp),
                  ),
                  24.verticalSpace,
                  Container(
                    width: 120.h,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: AppColors.dPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: 45.w,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    child: Column(
                      children: List.generate(plans.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: SubscriptionPlanCard(
                            plan: plans[index],
                            onTap: () => selectPlan(index),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      backgroundColor: AppColors.dPrimary,
                      onPressed: () {
                        context.pushNamed(AppRoute.tabs.name);
                      },
                      text: buttonText,
                    ),
                  ),
                  30.verticalSpace,
                  Text(
                    'By placing this order, you agree to the Terms of Services, Privacy Policy turned off at 24 hours before the end of the current period.',
                    textAlign: TextAlign.center,
                    style: textStyle12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
