import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:az_incident_alert/providers/subscription_provider.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/services/push_notification_service.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      log('[SplashScreen] 🚀 Starting app initialization...');

      // Step 1: Get device ID (fast)
      await _getDeviceId();

      // Step 2: Initialize FirebaseService BEFORE notifications
      log('[SplashScreen] 🔥 Initializing FirebaseService...');
      await FirebaseService.instance.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log('[SplashScreen] ⚠️ FirebaseService init timed out');
        },
      );

      // Step 3: Initialize NotificationService (will request permissions on first launch)
      log('[SplashScreen] 📱 Initializing NotificationService...');
      await NotificationService.init();

      // Step 4: Initialize SubscriptionProvider and check status
      log('[SplashScreen] 💳 Initializing SubscriptionProvider...');
      final userId = await SharedPrefs.instance.getOrGenerateUserId();

      final subscriptionProvider = SubscriptionProvider();

      // Initialize with timeout
      await subscriptionProvider.initialize(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('[SplashScreen] ⚠️ SubscriptionProvider init timed out');
        },
      );

      // Check subscription status
      final hasAccess = subscriptionProvider.hasAccess;
      log('[SplashScreen] 📊 Has access: $hasAccess');
      log('[SplashScreen] 📊 Status: ${subscriptionProvider.status}');

      log('[SplashScreen] ✅ All initialization complete!');

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate to appropriate screen
      if (mounted) {
        if (hasAccess) {
          log('[SplashScreen] ✅ Navigating to tabs');
          context.goNamed(AppRoute.tabs.name);
        } else {
          log('[SplashScreen] 📝 Navigating to subscription screen');
          context.goNamed(AppRoute.subscriptionScreen.name);
        }
      }
    } catch (e, stackTrace) {
      log('[SplashScreen] ❌ Initialization error: $e');
      log('[SplashScreen] Stack trace: $stackTrace');

      // On error, go to subscription screen
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        context.goNamed(AppRoute.subscriptionScreen.name);
      }
    }
  }

  Future<void> _getDeviceId() async {
    log('[SplashScreen] 📱 Getting device ID...');
    if (SharedPrefs.instance.deviceId != null) {
      log('[SplashScreen] ✅ Device ID already exists');
      return;
    }

    var deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      deviceId = androidDeviceInfo.id;
    }

    SharedPrefs.instance.setDeviceId(deviceId ?? "");
    log('[SplashScreen] ✅ Device ID: $deviceId');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8833A), // Orange at top
              Color(0xFFF4B942), // Yellow at bottom
            ],
          ),
        ),
        child: Stack(
          children: [
            // Cactus image - bottom aligned to screen center
            Positioned(
              bottom: screenHeight * 0.5, // Bottom of image at screen center
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/png/Cactus_With_Light.png',
                height: screenHeight * 0.4,
                fit: BoxFit.contain,
              ),
            ),
            // Title - top aligned to bottom half start
            Positioned(
              top: screenHeight * 0.5, // Top of title at bottom half start
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // App Title
                  Text(
                    "Cactus Alert",
                    style: textStyle22Bold.copyWith(
                      fontSize: 42,
                      color: const Color(0xFF5C2E1A), // Dark brown
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Loading Indicator
                  const CircularProgressIndicator(
                    color: Color(0xFF5C2E1A), // Dark brown
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
