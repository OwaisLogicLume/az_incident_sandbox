import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_button.dart';
import 'package:az_incident_alert/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> showFilterSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: context.appColors.bgColor,
    isDismissible: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        height: MediaQuery.of(context).size.height * .8,
        child: Consumer<IncidentsProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter With symbol codes',
                              style: textStyle20Bold,
                            ),
                            TextButton(
                              onPressed: provider.clearFilters,
                              child: Text('Clear', style: textStyle14),
                            ),
                          ],
                        ),
                        10.h.verticalSpace,
                        Wrap(
                          children: provider.symbolCodes.entries
                              .map(
                                (e) => AppChip(
                                  text: e.key,
                                  imagePath: e.value,
                                  isSelected: provider.selectedSymbolCodes
                                      .contains(e.key),
                                  onTap: () {
                                    provider.changeSelectedSymbols(e.key);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                10.h.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: context.pop,
                        text: 'Cancel',
                        colorType: AppButtonColorType.secondary,
                      ),
                    ),
                    10.w.horizontalSpace,
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                          provider.filterIncidents();
                          context.pop();
                        },
                        text: 'Filter',
                        colorType: AppButtonColorType.primary,
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      );
    },
  );
}
