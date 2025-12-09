import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MapLayerSwitch extends StatelessWidget {
  const MapLayerSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.bgColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(
                context: context,
                label: 'Day',
                mapType: KDayMapType,
                isSelected: provider.mapType == KDayMapType,
                onTap: () {
                  print('[MapLayerSwitch] Day button tapped');
                  print('[MapLayerSwitch] Current mapType before change: ${provider.mapType}');
                  try {
                    provider.changeMapType(KDayMapType);
                    print('[MapLayerSwitch] changeMapType(KDayMapType) called');
                    print('[MapLayerSwitch] Current mapType after change: ${provider.mapType}');
                  } catch (e) {
                    print('[MapLayerSwitch] ERROR: $e');
                  }
                },
                isFirst: true,
              ),
              _buildSegment(
                context: context,
                label: 'Night',
                mapType: KNightMapType,
                isSelected: provider.mapType == KNightMapType,
                onTap: () {
                  print('[MapLayerSwitch] Night button tapped');
                  print('[MapLayerSwitch] Current mapType before change: ${provider.mapType}');
                  try {
                    provider.changeMapType(KNightMapType);
                    print('[MapLayerSwitch] changeMapType(KNightMapType) called');
                    print('[MapLayerSwitch] Current mapType after change: ${provider.mapType}');
                  } catch (e) {
                    print('[MapLayerSwitch] ERROR: $e');
                  }
                },
              ),
              _buildSegment(
                context: context,
                label: 'Satellite',
                mapType: kSatelliteMapType,
                isSelected: provider.mapType == kSatelliteMapType,
                onTap: () => provider.changeMapType(kSatelliteMapType),
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String label,
    required String mapType,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.secondaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(25) : Radius.zero,
            right: isLast ? const Radius.circular(25) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: textStyle12SemiBold.copyWith(
            color: isSelected
                ? context.appColors.bgColor
                : context.appColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
