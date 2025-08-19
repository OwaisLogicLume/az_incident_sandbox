import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/widgets/app_scaffold.dart';
import 'package:az_incident_alert/widgets/filter_sheet.dart';
import 'package:az_incident_alert/widgets/incident_tile.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
        return AppScaffold(
          appbarTitle: 'Alert',
          pinned: true,
          appbarActions: [
            IconButton(
              onPressed: () {
                showFilterSheet(
                  AppNavigator.rootNavigator.currentContext ?? context,
                );
              },
              icon: Icon(
                provider.isFiltersSelected
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
            )
          ],

          /// Drop down UI

          // appbarBottom: PreferredSize(
          //   preferredSize: Size.fromHeight(80.h),
          //   child: Column(
          //     children: [
          //       _buildDropDownmenu(provider),
          //       10.h.verticalSpace,
          //       Divider(height: 1.h),
          //     ],
          //   ),
          // ),

          body: provider.isAlertLoading
              ? Center(
                  child: SpinKitDoubleBounce(
                    color: context.appColors.primaryColor,
                  ),
                )
              : provider.filteredIncidents.isEmpty
                  ? Center(
                      child: Text(
                        'Not having any incident of following type.',
                        style: textStyle16SemiBold,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          ...provider.filteredIncidents.map(
                            (e) => NewIncidentTile(
                              incident: e,
                            ),
                          ),
                          70.verticalSpace,
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
