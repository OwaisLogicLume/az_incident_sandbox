import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoConnectionWidget extends StatelessWidget {
  const NoConnectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(15.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Internrt!',
              style: textStyle22Bold.copyWith(fontSize: 35),
            ),
            10.h.verticalSpace,
            Text(
              'Looks Like you have lost your connection. Try to connect with Internet and get the live Incidents.',
              style: textStyle16,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
