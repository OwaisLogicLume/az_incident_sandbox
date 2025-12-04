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
  void initState() {
    super.initState();
    // Load stations from Firebase when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsProvider>().getAllStations();
    });
  }

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
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.selectedUnits.length,
                    itemBuilder: (context, index) {
                      final unit = provider.selectedUnits[index];
                      final isWildcard = provider.isWildcard(unit);
                      final displayName = isWildcard
                          ? provider.getWildcardDisplayName(unit)
                          : unit;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 1,
                        child: ListTile(
                          leading: Icon(
                            isWildcard ? Icons.star : Icons.circle,
                            color: context.appColors.primaryColor,
                          ),
                          title: Text(
                            isWildcard ? '$displayName ($unit)' : displayName,
                            style: textStyle16Bold.copyWith(
                              color: isWildcard
                                  ? context.appColors.primaryColor
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              _confirmRemoveUnit(
                                  context, provider, unit, isWildcard, displayName);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      );
    });
  }

  void _confirmRemoveUnit(
    BuildContext context,
    IncidentsProvider provider,
    String unit,
    bool isWildcard,
    String displayName,
  ) {
    final message = isWildcard
        ? 'Stop following $displayName?\n\nYou will no longer receive alerts for any units matching this pattern.'
        : 'Remove $unit from your alerts?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeSelectedUnit(unit);
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: isWildcard
                    ? 'Stopped following $displayName'
                    : 'Removed $unit',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
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
          // CRITICAL FIX: Bottom sheet selection is the source of truth
          // 1. Remove units that were deselected (in provider but not in selectedUnits)
          final unitsToRemove = provider.selectedUnits
              .where((unit) => !selectedUnits.contains(unit))
              .toList();
          for (var unit in unitsToRemove) {
            provider.removeSelectedUnit(unit);
          }

          // 2. Add new units (in selectedUnits but not in provider)
          for (var unit in selectedUnits) {
            if (!provider.selectedUnits.contains(unit)) {
              provider.addSelectedUnit(unit, () {
                // Already exists callback (shouldn't happen with new logic)
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
