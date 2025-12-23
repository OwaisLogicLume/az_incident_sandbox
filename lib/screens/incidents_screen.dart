import 'dart:async';
import 'dart:developer';

import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/providers/theme_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/incident_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class IncidencesScreen extends StatefulWidget {
  const IncidencesScreen({super.key});

  @override
  State<IncidencesScreen> createState() => _IncidencesScreenState();
}

class _IncidencesScreenState extends State<IncidencesScreen> {
  int _tapCount = 0;
  Timer? _doubleTapTimer;
  final _doubleTapDuration = const Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    // logEvent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsProvider>().getAllStations();
      context.read<IncidentsProvider>().getIncidents(
            onSuccess: () => log('Initial incidents fetched successfully'),
            onError: (error) => log('Error fetching initial incidents: $error'),
          );
    });
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTitleTap() {
    _tapCount++;
    _doubleTapTimer?.cancel();

    if (_tapCount == 1) {
      _doubleTapTimer = Timer(_doubleTapDuration, () {
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      _doubleTapTimer?.cancel();
      _tapCount = 0;

      // Allow theme switching in both light and dark mode
      final themeProvider = context.read<ThemeProvider>();
      themeProvider.cycleTheme();

      // Show toast with theme name
      Fluttertoast.showToast(
        msg: "Theme: ${themeProvider.themeName}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(builder: (context, provider, _) {
      return AppScaffold(
        appbarActions: [
          IconButton(onPressed: (){
           context.pushNamed(AppRoute.rdioscannerScreen.name);
          }, icon: Icon(CupertinoIcons.speaker)),
          // IconButton(
          //   onPressed: () {
          //     logEvent();
          //   },
          //   icon: const Icon(Icons.remove),
          // ),
          IconButton(
            onPressed: () {
              context.pushNamed(AppRoute.alertScreen.name);
            },
            icon: const Icon(CupertinoIcons.bell),
          ),
          IconButton(
            onPressed: () {
              provider.setLoading(true);
              provider.getIncidents(
                onSuccess: () => log('Manual refresh successful'),
                onError: (error) => log('Error during manual refresh: $error'),
              );
            },
            icon: const Icon(CupertinoIcons.refresh),
          ),
        ],
        appbarTitleWidget: GestureDetector(
          onTap: _handleTitleTap,
          child: const Text(
            'Cactus Alert',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: Stack(
          alignment: Alignment.bottomRight,
          children: [
            provider.isLoading
                ? Center(
                    child: SpinKitDoubleBounce(
                      color: context.appColors.primaryColor,
                    ),
                  )
                : provider.filteredIncidents.isEmpty
                    ? Center(
                        child: Text(
                          'Currently, there are no incidents.',
                          style: textStyle16SemiBold,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 70),
                        children: [
                          ...provider.filteredIncidents.map(
                            (e) => NewIncidentTile(
                              incident: e,
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      );
    });
  }

}
