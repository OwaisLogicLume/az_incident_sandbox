import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';

class FireStationToggle extends StatefulWidget {
  const FireStationToggle({super.key});

  @override
  State<FireStationToggle> createState() => _FireStationToggleState();
}

class _FireStationToggleState extends State<FireStationToggle> {
  int _tapCount = 0;
  Timer? _doubleTapTimer;
  final _doubleTapDuration = const Duration(milliseconds: 700);

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTap(IncidentsProvider provider) {
    if (provider.isLoadingFireStations) return;

    _tapCount++;

    // Cancel existing timer
    _doubleTapTimer?.cancel();

    if (_tapCount == 1) {
      // Start timer for double tap detection
      _doubleTapTimer = Timer(_doubleTapDuration, () {
        // Single tap timeout - perform toggle
        provider.toggleFireStations();
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      // Double tap detected
      _doubleTapTimer?.cancel();
      _tapCount = 0;

      // Only switch to Phoenix mode if in ALL_REGIONAL mode
      if (provider.fireStationMode == FireStationDisplayMode.allRegional) {
        provider.switchToPhoenixOnly();
      } else {
        // In other modes, double tap acts like single tap
        provider.toggleFireStations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
        final mode = provider.fireStationMode;
        final isLoading = provider.isLoadingFireStations;
        final isActive = mode != FireStationDisplayMode.off;

        return GestureDetector(
          onTap: () => _handleTap(provider),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? context.appColors.primaryColor.withOpacity(0.9)
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Loading indicator
                  if (isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isActive ? Colors.white : context.appColors.primaryColor,
                        ),
                      ),
                    ),

                  // Icon with badge
                  if (!isLoading)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: isActive ? Colors.white : context.appColors.primaryColor,
                          size: 24,
                        ),
                        // Badge showing mode
                        if (mode != FireStationDisplayMode.off)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: mode == FireStationDisplayMode.phoenixOnly
                                    ? Colors.orange
                                    : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  mode == FireStationDisplayMode.phoenixOnly ? 'P' : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
