import 'dart:developer';

import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NewIncidentTile extends StatelessWidget {
  const NewIncidentTile({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<IncidentsProvider>().changeCurrentLatLng(incident.latLng);
        log("incident.latlan========>${incident.latLng}");
        context.read<AppProvider>().changeIndex(1);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        padding: EdgeInsets.all(20.r),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: context.read<IncidentsProvider>().incidentMatchesSelectedUnits(incident)
              ? context.appColors.ternaryColor
              : context.isDark
                  ? Colors.black38
                  : Colors.white54,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(context),
            10.verticalSpace,
            _buildUnitsView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(incident.natureDesc ?? '', style: textStyle16Bold),
            ),
            10.horizontalSpace,
            Text('Ch. ${incident.channel}', style: textStyle14),
          ],
        ),
        Text(incident.genLocInfo ?? '', style: textStyle14)
      ],
    );
  }

  Widget _buildUnitsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...separateUnits(incident.unitsWithLables ?? []).entries.map(
              (e) => Column(
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${e.key.trim()}: ',
                      style: textStyle14,
                      children: [
                        TextSpan(
                          text: e.value.join(' | '),
                          style: textStyle12.copyWith(
                            color: context.appColors.tile5Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  5.verticalSpace,
                ],
              ),
            )
      ],
    );
  }

  Map<String, List<String>> separateUnits(List<String> lstUnits) {
    final Map<String, List<String>> separatedUnits = {};

    for (String strUnit in lstUnits) {
      List<String> separatedUnit = strUnit.split(':');
      if (separatedUnits.containsKey(separatedUnit.last)) {
        separatedUnits[separatedUnit.last]!.add(separatedUnit.first);
      } else {
        separatedUnits[separatedUnit.last] = [separatedUnit.first];
      }
    }

    return separatedUnits;
  }
}
