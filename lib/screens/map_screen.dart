import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/esri_map.dart';
import 'package:az_incident_alert/widgets/map_layer_switch.dart';
import 'package:az_incident_alert/widgets/fire_station_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.latLng,
  });

  final LatLng? latLng;

  @override
  State<MapScreen> createState() => _MapScreenState();

  
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(
    BuildContext context,
  ) {
    return AppScaffold(

      body: SafeArea(
        child: Stack(
          children: [
            MapBoxWidget(
              initialLatLng: LatLng(
                widget.latLng?.latitude ?? kPhoenixLatLng.latitude,
                widget.latLng?.longitude ?? kPhoenixLatLng.longitude,
              ),
            ),

            // Map layer switch in top-right corner
            Positioned(
              top: 16.h,
              right: 16.w,
              child: const MapLayerSwitch(),
            ),

            // Fire station toggle below map layer switch
            Positioned(
              top: 80.h,
              right: 16.w,
              child: const FireStationToggle(),
            ),
          ],
        ),
      ),
    );
  }
}