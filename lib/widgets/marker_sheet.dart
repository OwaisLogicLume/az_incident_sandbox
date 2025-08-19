import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/extensions/date_time_ext.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<dynamic> showMarkerInfoSheet(Incident e) {
  return showModalBottomSheet(
    context: AppNavigator.rootNavigator.currentContext!,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(15.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.natureDesc ?? '', style: textStyle18Bold),
            15.h.verticalSpace,
            Table(
              defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
              border: TableBorder.all(color: context.appColors.primaryColor),
              children: [
                _tableRow(
                  context,
                  'Nature',
                  Text(e.nature ?? '', style: textStyle14),
                  true,
                ),
                _tableRow(
                  context,
                  'Description',
                  Text(e.natureDesc ?? '', style: textStyle14),
                  false,
                ),
                _tableRow(
                  context,
                  'Approximate Location',
                  Text(e.genLocInfo ?? '', style: textStyle14),
                  true,
                ),
                _tableRow(
                  context,
                  'Time Dispatched',
                  Text(e.date?.toddMMYYYYHHMM ?? '', style: textStyle14),
                  false,
                ),
                _tableRow(
                  context,
                  'Channel',
                  Text(e.channel ?? '', style: textStyle14),
                  true,
                ),
                _tableRow(
                  context,
                  'Units',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: e.unitsWithLables
                            .map((el) => Text(el, style: textStyle14))
                            .toList() ??
                        [],
                  ),
                  false,
                ),
              ],
            ),
            20.h.verticalSpace,
          ],
        ),
      );
    },
  );
}

_tableRow(BuildContext context, String heading, Widget value, bool isSelected) {
  return TableRow(
    children: [
      _tableCell(Text(heading, style: textStyle14SemiBold)),
      _tableCell(value),
    ],
    decoration: BoxDecoration(
        color: context.appColors.primaryColor.withAlpha(isSelected ? 100 : 40)),
  );
}

_tableCell(Widget child) {
  return TableCell(
    child: Container(
      padding: EdgeInsets.all(8.r),
      child: child,
    ),
  );
}
