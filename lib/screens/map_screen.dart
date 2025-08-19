import 'dart:developer';

import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/esri_map.dart';
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
      
      body: Padding(
        padding: EdgeInsets.only(bottom: 75.h),
        child: Stack(
          children: [
            MapBoxWidget(
              initialLatLng: LatLng(
                widget.latLng?.latitude ?? kPhoenixLatLng.latitude,
                widget.latLng?.longitude ?? kPhoenixLatLng.longitude,
              ),
            ),

            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h,right: 10.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showMaptypeSheet(context);
                      },
                      child: Container(
                        height: 55.h,
                        width: 55.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: context.appColors.bgColor,
                        ),
                        child: const Icon(Icons.layers_outlined),
                      ),
                    ),
                    10.verticalSpace,
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showMaptypeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: 170.h,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Type',
              style: textStyle16SemiBold,
            ),
            20.h.verticalSpace,
            
            Row(
              children: [
                buildDayNightToggleContainer(context),
                30.horizontalSpace,
                // buildMaptypeContainer(
                //     context, kSatelliteMapType, kSatelliteMapImage),
              ],
            ),
          ],
        ),
      );
    },
  );
}


  // Widget buildMaptypeContainer(
  //   BuildContext context,
  //   String type,
  //   String image,
  // ) {
  //   return Consumer<IncidentsProvider>(builder: (context, provider, _) {
  //     log('assigned type => $type');
  //     log('provider map type => ${provider.mapType}');
  //     return Column(
  //       children: [
  //         GestureDetector(
  //           onTap: () {
  //             provider.changeMapType(type);
  //           },
  //           child: Container(
              
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(12.r),
  //               border: type == provider.mapType
  //                   ? Border.all(
  //                       width: 2,
  //                       color: context.appColors.primaryColor,
  //                     )
  //                   : null,
  //             ),
  //             child: AnimatedContainer(
  //               curve: Curves.easeIn,
  //               duration: const Duration(seconds: 1),
  //               height: 60.h,
  //               width: 60.h,
  //               decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(12.r),
  //                   color: context.appColors.bgColor,
  //                   image: DecorationImage(image: AssetImage(image,)),
  //                   border: Border.all(
  //                     width: 2,
  //                     color: context.isDark ? AppColors.black : AppColors.white,
  //                   )),
  //             ),
  //           ),
  //         ),
  //          20.h.verticalSpace,
  //         Text(
  //           type,
  //           style: type == provider.mapType ? textStyle14Bold : textStyle14,
  //         ),
  //            20.verticalSpace,
  //       ],
  //     );
  //   });
  // }
Widget buildDayNightToggleContainer(BuildContext context) {
  return Consumer<IncidentsProvider>(
    builder: (context, provider, _) {
      final mapType = provider.mapType;
 
final lastDayNightType = provider.lastDayNightMapType;

final isSatellite = mapType == kSatelliteMapType;
final isNightMode = lastDayNightType == KNightMapType;


return Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
   
    Column(
      children: [
        GestureDetector(
          onTap: () {
            final newType = (lastDayNightType == KNightMapType) ? KDayMapType : KNightMapType;
            provider.changeMapType(newType);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                width: 2,
                color: (mapType == KDayMapType || mapType == KNightMapType)
                    ? context.appColors.primaryColor
                    : Colors.transparent,
              ),
            ),
            child: AnimatedContainer(
              height: 60.h,
              width: 60.h,
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                image: DecorationImage(
                  image: AssetImage(
                    isNightMode ? kNightMapImage : kNormalMapImage,
                  ),
                  fit: BoxFit.cover,
                ),
                color: context.appColors.bgColor,
                border: Border.all(
                  width: 2,
                  color: context.isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ),
        ),
        6.verticalSpace,
        Text(
          isNightMode ? 'Night' : 'Day',
          style: (mapType == KDayMapType || mapType == KNightMapType)
              ? textStyle14Bold
              : textStyle14,
        ),
      ],
    ),

    20.horizontalSpace,

    // Satellite toggle
    Column(
      children: [
        GestureDetector(
          onTap: () {
            // Toggle satellite on/off:
            final newType = isSatellite ? lastDayNightType : kSatelliteMapType;
            provider.changeMapType(newType);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                width: 2,
                color: isSatellite
                    ? context.appColors.primaryColor
                    : Colors.transparent,
              ),
            ),
            child: AnimatedContainer(
              height: 60.h,
              width: 60.h,
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                image: const DecorationImage(
                  image: AssetImage(kSatelliteMapImage),
                  fit: BoxFit.cover,
                ),
                color: context.appColors.bgColor,
                border: Border.all(
                  width: 2,
                  color: context.isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ),
        ),
        6.verticalSpace,
        Text(
          'Map',
          style: isSatellite ? textStyle14Bold : textStyle14,
        ),
      ],
    ),
  ],
);
    },
  );
}

}