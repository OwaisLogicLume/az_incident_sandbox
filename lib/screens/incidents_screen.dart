import 'dart:developer';

import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/incident_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class IncidencesScreen extends StatefulWidget {
  const IncidencesScreen({super.key});

  @override
  State<IncidencesScreen> createState() => _IncidencesScreenState();
}

class _IncidencesScreenState extends State<IncidencesScreen> {
  @override
  void initState() {
    super.initState();
    // logEvent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsProvider>().getIncidents(
            onSuccess: () => log('Initial incidents fetched successfully'),
            onError: (error) => log('Error fetching initial incidents: $error'),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(builder: (context, provider, _) {
      return AppScaffold(
        appbarActions: [
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
          PopupMenuButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 180, height: 160),
            position: PopupMenuPosition.under,
            itemBuilder: (context) {
              return [
                _buildPopMenuItem(
                    'Light', CupertinoIcons.sun_max_fill, ThemeMode.light),
                _buildPopMenuItem('Dark', CupertinoIcons.moon, ThemeMode.dark),
                _buildPopMenuItem(
                    'System', CupertinoIcons.gear_big, ThemeMode.system),
              ];
            },
          ),
        ],
        appbarTitle: 'CACTUS ALERT',
        titleStyle: textStyle22Bold.copyWith(
          fontFamily: 'sedansc',
          fontSize: 19,
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

  PopupMenuItem _buildPopMenuItem(String text, IconData icon, ThemeMode mode) {
    return PopupMenuItem(
      child: Consumer<AppProvider>(builder: (context, provider, _) {
        return ListTile(
          onTap: () {
            provider.changeThemeMode(mode);
          },
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: Icon(icon),
          title: Text(text, style: textStyle14),
          trailing: provider.currentThemeMode == mode
              ? const CircleAvatar(radius: 6, backgroundColor: AppColors.lTile3)
              : null,
        );
      }),
    );
  }
}
