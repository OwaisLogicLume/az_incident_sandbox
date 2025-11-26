import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/unit_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(builder: (context, provider, _) {
      return AppScaffold(
        appbarTitle: 'Alerts',
        appbarActions: [
          IconButton(
            onPressed: () {
              _showUnitSelectionBottomSheet(context, provider);
            },
            icon: const Icon(Icons.add),
          )
        ],
        body: provider.isAlertLoading
            ? Center(
                child: SpinKitDoubleBounce(
                  color: context.appColors.primaryColor,
                ),
              )
            : provider.selectedUnits.isEmpty
                ? Center(
                    child: Text(
                      'No units added.',
                      style: textStyle14,
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.selectedUnits.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: index == 0
                                ? BorderSide(
                                    color: context.appColors.primaryColor)
                                : BorderSide.none,
                            bottom: BorderSide(
                                color: context.appColors.primaryColor),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.selectedUnits.toList()[index],
                              style: textStyle16Bold,
                            ),
                            IconButton(
                              onPressed: () {
                                provider.removeSelectedUnit(
                                    provider.selectedUnits.toList()[index]);
                              },
                              icon: const Icon(Icons.remove),
                            )
                          ],
                        ),
                      );
                    },
                  ),
      );
    });
  }

  void _showUnitSelectionBottomSheet(
    BuildContext context,
    IncidentsProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => UnitSelectionBottomSheet(
        currentlySelectedUnits: provider.selectedUnits.toSet(),
        onUnitsSelected: (selectedUnits) {
          // Add new units to existing selection
          for (var unit in selectedUnits) {
            if (!provider.selectedUnits.contains(unit)) {
              provider.addSelectedUnit(unit, () {
                // Already exists callback
                Fluttertoast.showToast(
                  msg: 'The unit $unit is already saved for alerts.',
                );
              });
            }
          }
        },
      ),
    );
  }
}
