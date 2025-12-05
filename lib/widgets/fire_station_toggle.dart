import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';

class FireStationToggle extends StatelessWidget {
  const FireStationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
        final isActive = provider.showFireStations;
        final isLoading = provider.isLoadingFireStations;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () async {
                    await provider.toggleFireStations();
                  },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.dPrimary.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive ? Colors.white : AppColors.dPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.local_fire_department,
                      color: isActive ? Colors.white : AppColors.dPrimary,
                      size: 24,
                    ),
            ),
          ),
        );
      },
    );
  }
}
