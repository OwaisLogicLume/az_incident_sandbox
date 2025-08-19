import 'dart:async';

import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/screens/incidents_screen.dart';
import 'package:az_incident_alert/screens/map_screen.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:provider/provider.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({
    super.key,
    // required this.navigationShell,
  });

  // final StatefulNavigationShell navigationShell;

  @override
  State<StatefulWidget> createState() {
    return _TabScreenState();
  }
}

class _TabScreenState extends State<TabScreen> {


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return SafeArea(
      child: Consumer<AppProvider>(builder: (context, provider, _) {
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: false,
          body: [
            const IncidencesScreen(),
            MapScreen(latLng: context.read<IncidentsProvider>().currentLatLng),
          ][provider.currentIndex],
          bottomNavigationBar: bottomNavigationBar(provider, isDark),
        );
      }),
    );
  }

  Widget bottomNavigationBar(
    AppProvider provider,
    bool isDark,
  ) {
    /// Snake Navigation bar
    return SnakeNavigationBar.color(
      height: 60.h,
      elevation: 30,
      backgroundColor: context.appColors.bgColor,
      snakeViewColor: context.appColors.primaryColor,
      selectedItemColor: context.appColors.bgColor,
      selectedLabelStyle: TextStyle(color: context.appColors.bgColor),
      behaviour: SnakeBarBehaviour.pinned,
      snakeShape: SnakeShape.rectangle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      padding: EdgeInsets.all(10.r),
      currentIndex: provider.currentIndex,
      onTap: _onTabChange,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          label: 'Arizona firescanner',
          activeIcon: Icon(CupertinoIcons.house_fill),
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.map),
          label: 'Alerts',
          activeIcon: Icon(CupertinoIcons.map_fill),
        ),
      ],
    );
  }

  _onTabChange(int index) {
    if (index == 1) {
      context.read<IncidentsProvider>().changeCurrentLatLng(kPhoenixLatLng);
    }

    context.read<AppProvider>().changeIndex(index);
  }
}
