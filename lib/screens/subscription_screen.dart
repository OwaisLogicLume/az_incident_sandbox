import 'dart:developer';

import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/providers/subscription_provider.dart';
import 'package:az_incident_alert/services/revenue_cat_service.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_button.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/subscription_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final List<Plan> plans;
  final RevenueCatService _revenueCatService = RevenueCatService();
  final SubscriptionProvider _subscriptionProvider = SubscriptionProvider();

  bool _isLoading = true;
  bool _isPurchasing = false;
  Package? _monthlyPackage;
  Package? _yearlyPackage;

  @override
  void initState() {
    super.initState();
    plans = _getStaticPlans();
    _initializeRevenueCat();
  }

  Future<void> _initializeRevenueCat() async {
    try {
      setState(() => _isLoading = true);

      // Get consistent device ID for RevenueCat
      final userId = await SharedPrefs.instance.getOrGenerateUserId();
      log('[SubscriptionScreen] Using user ID: $userId');

      // Initialize RevenueCat with consistent user ID
      await _revenueCatService.initialize(userId);

      // Fetch offerings
      await _revenueCatService.fetchOfferings();

      // Get packages
      _monthlyPackage = _revenueCatService.getMonthlyPackage();
      _yearlyPackage = _revenueCatService.getYearlyPackage();

      log('Monthly package: ${_monthlyPackage?.storeProduct.priceString}');
      log('Yearly package: ${_yearlyPackage?.storeProduct.priceString}');

      setState(() => _isLoading = false);
    } catch (e) {
      log('Error initializing RevenueCat: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Plan> _getStaticPlans() {
    return [
      Plan(
        title: 'YEARLY',
        price: '\$99.99/year',
        subtitle: '3 days free trial',
        isSelected: true,
      ),
      Plan(
        title: 'MONTHLY',
        price: '\$9.99/month',
        subtitle: '3 days free trial',
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

  Future<void> _handlePurchase() async {
    log('[SubscriptionScreen] 🚀 _handlePurchase called');

    if (_isPurchasing) {
      log('[SubscriptionScreen] ⚠️ Already purchasing, returning');
      return;
    }

    setState(() => _isPurchasing = true);
    log('[SubscriptionScreen] 📝 Set _isPurchasing = true');

    try {
      // Get selected plan
      final selectedPlanIndex = plans.indexWhere((plan) => plan.isSelected);
      log('[SubscriptionScreen] 📊 Selected plan index: $selectedPlanIndex');

      Package? selectedPackage;

      if (selectedPlanIndex == 0) {
        // Yearly
        selectedPackage = _yearlyPackage;
        log('[SubscriptionScreen] 📦 Selected yearly package: ${_yearlyPackage?.identifier}');
      } else {
        // Monthly
        selectedPackage = _monthlyPackage;
        log('[SubscriptionScreen] 📦 Selected monthly package: ${_monthlyPackage?.identifier}');
      }

      if (selectedPackage == null) {
        log('[SubscriptionScreen] ❌ Package is null!');
        Fluttertoast.showToast(msg: 'Package not available. Please try again.');
        return;
      }

      // Purchase the package
      log('[SubscriptionScreen] 💳 Starting purchase...');
      final customerInfo = await _revenueCatService.purchasePackage(selectedPackage);
      log('[SubscriptionScreen] 💳 Purchase completed, customerInfo: ${customerInfo != null ? "NOT NULL" : "NULL"}');

      if (customerInfo != null) {
        log('[SubscriptionScreen] 📊 Active entitlements count: ${customerInfo.entitlements.active.length}');
        log('[SubscriptionScreen] 📊 All entitlements count: ${customerInfo.entitlements.all.length}');

        if (customerInfo.entitlements.active.isNotEmpty) {
          // CRITICAL: Save subscription status via SubscriptionProvider
          log('[SubscriptionScreen] ✅ Purchase successful! Active entitlements found');
          log('[SubscriptionScreen] 💾 Saving subscription status via SubscriptionProvider...');
          await _subscriptionProvider.handlePurchaseSuccess(customerInfo);
          log('[SubscriptionScreen] ✅ Subscription status saved');

          Fluttertoast.showToast(
            msg: 'Subscription successful! Enjoy your 3-day trial.',
            backgroundColor: Colors.green,
          );

          // Navigate to tabs immediately without showing state change
          log('[SubscriptionScreen] 🧭 Checking mounted state: $mounted');
          if (mounted) {
            log('[SubscriptionScreen] 🧭 Navigating to tabs...');
            context.goNamed(AppRoute.tabs.name);
            log('[SubscriptionScreen] 🧭 Navigation called, returning early');
          } else {
            log('[SubscriptionScreen] ⚠️ Widget not mounted, cannot navigate');
          }
          return; // Exit early to prevent setState in finally block
        } else {
          log('[SubscriptionScreen] ⚠️ Purchase completed but no active entitlements');
        }
      } else {
        log('[SubscriptionScreen] ⚠️ customerInfo is null');
      }
    } catch (e, stackTrace) {
      log('[SubscriptionScreen] ❌ Purchase error: $e');
      log('[SubscriptionScreen] ❌ Stack trace: $stackTrace');
      Fluttertoast.showToast(
        msg: 'Purchase failed. Please try again.',
        backgroundColor: Colors.red,
      );
    } finally {
      log('[SubscriptionScreen] 🏁 Finally block - mounted: $mounted');
      if (mounted) {
        setState(() => _isPurchasing = false);
        log('[SubscriptionScreen] 📝 Set _isPurchasing = false');
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    log('[SubscriptionScreen] 🔄 Restore purchases called');

    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);

    try {
      log('[SubscriptionScreen] 🔄 Restoring purchases...');

      final success = await _subscriptionProvider.restorePurchases();

      if (success) {
        Fluttertoast.showToast(
          msg: 'Purchases restored successfully!',
          backgroundColor: Colors.green,
        );

        // Navigate to tabs immediately without showing state change
        if (mounted) {
          context.goNamed(AppRoute.tabs.name);
        }
        return; // Exit early to prevent setState in finally block
      } else {
        Fluttertoast.showToast(
          msg: 'No active purchases found.',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      log('[SubscriptionScreen] ❌ Error restoring purchases: $e');
      Fluttertoast.showToast(
        msg: 'Failed to restore purchases. Please try again.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppScaffold(
        body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.dPrimary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 16.h),
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
                            onPressed: _handlePurchase,
                            text: 'Start 3 day free trial',
                          ),
                        ),
                        30.verticalSpace,
                        Text(
                          'By placing this order, you agree to the Terms of Services, Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.',
                          textAlign: TextAlign.center,
                          style: textStyle12,
                        ),
                        16.verticalSpace,
                        TextButton(
                          onPressed: _handleRestorePurchases,
                          child: Text(
                            'Restore Purchases',
                            style: textStyle14Bold.copyWith(
                              color: AppColors.dPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
