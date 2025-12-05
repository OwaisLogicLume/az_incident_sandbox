import 'dart:async';
import 'dart:developer';

import 'package:az_incident_alert/main.dart';
import 'package:az_incident_alert/providers/subscription_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // startTimer(),
    checkTrialStatus(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: context.appColors.bgColor,
        child: Center(
          child: Text(
            "App \nLogo",
            style: textStyle22Bold.copyWith(fontSize: 42),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // startTimer() {
  //   var duration = const Duration(milliseconds: 2000);
  //   return Future.delayed(duration, () {
  //     context.goNamed(AppRoute.subscriptionScreen.name);
  //   });
  // }
}

void checkTrialStatus(BuildContext context) async {
  try {
    log('[SplashScreen] Checking subscription status...');

    // Get SubscriptionProvider to check subscription status
    final subscriptionProvider = context.read<SubscriptionProvider>();

    // Refresh subscription status from RevenueCat
    await subscriptionProvider.refreshSubscriptionStatus();

    final hasAccess = subscriptionProvider.hasAccess;
    final status = subscriptionProvider.status;

    log('[SplashScreen] Subscription status: $status');
    log('[SplashScreen] Has access: $hasAccess');

    if (hasAccess) {
      // User has active trial or subscription, navigate to tabs
      log('[SplashScreen] ✅ User has access, navigating to tabs');
      if (context.mounted) {
        context.goNamed(AppRoute.tabs.name);
      }
    } else {
      // No subscription, navigate to subscription screen
      log('[SplashScreen] ❌ No subscription, navigating to subscription screen');
      if (context.mounted) {
        context.goNamed(AppRoute.subscriptionScreen.name);
      }
    }
  } catch (e, stackTrace) {
    log('[SplashScreen] ❌ Error checking subscription: $e');
    log('[SplashScreen] Stack trace: $stackTrace');

    // On error, navigate to subscription screen to be safe
    if (context.mounted) {
      context.goNamed(AppRoute.subscriptionScreen.name);
    }
  }
}
