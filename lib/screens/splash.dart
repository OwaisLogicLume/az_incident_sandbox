import 'dart:async';

import 'package:az_incident_alert/main.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  final valid = await SharedPrefs.instance.isTrialStillValid();
  if (valid) {
    context.pushReplacementNamed(AppRoute.home.name);
  } else {
    context.pushReplacementNamed(AppRoute.subscriptionScreen.name);
  }
}
