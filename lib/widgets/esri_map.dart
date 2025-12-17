import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/models/fire_station_model.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/widgets/marker_sheet.dart';
import 'package:image/image.dart' as img;

class MapBoxWidget extends StatefulWidget {
  const MapBoxWidget({super.key, this.initialLatLng});
  final latlng.LatLng? initialLatLng;

  @override
  State<MapBoxWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapBoxWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotationManager? _fireStationAnnotationManager;
  final Map<String, Incident> _annotationIncidentMap = {};
  final Map<String, FireStation> _annotationFireStationMap = {};

  @override
  Widget build(BuildContext context) {
    final initialLatLng = widget.initialLatLng ?? kPhoenixLatLng;



    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
         final styleUri = _getStyleUri(provider);

         // Update fire station markers when showFireStations or fireStations list changes
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (_fireStationAnnotationManager != null) {
             if (provider.showFireStations && provider.fireStations.isNotEmpty) {
               // Remove existing markers first, then add new ones
               _removeFireStationMarkers().then((_) {
                 _addFireStationMarkers();
               });
             } else if (!provider.showFireStations) {
               _removeFireStationMarkers();
             }
           }
         });

        return MapWidget(

          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(
                initialLatLng.longitude,
                initialLatLng.latitude,
              ),
            ),
           zoom: widget.initialLatLng == kPhoenixLatLng ? 10.0 : 15.0,

          ),
          styleUri: styleUri,

          key: ValueKey("mapbox-map-${provider.mapType}"),

          mapOptions: MapOptions(
            constrainMode: ConstrainMode.HEIGHT_ONLY,
            contextMode: ContextMode.UNIQUE,
            pixelRatio: MediaQuery.of(context).devicePixelRatio,
          ),

          onMapCreated: _onMapCreated,
        );
      },
    );
  }
String _getStyleUri(IncidentsProvider provider) {
  if (provider.mapType == KDayMapType) {
    return "mapbox://styles/azincidentalert/cmb4lpzb800l101sda1ewfx4g";
  } else if (provider.mapType == KNightMapType) {
    return 'mapbox://styles/azincidentalert/cmb4ptheg00ji01qxch9ghb8c';
  } else if (provider.mapType == kSatelliteMapType) {
    return MapboxStyles.SATELLITE_STREETS;
  } else {
    return MapboxStyles.MAPBOX_STREETS;
  }
}





  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _fireStationAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    await _addMarkers();

    // Check if fire stations should be shown on map load
    final provider = context.read<IncidentsProvider>();
    if (provider.showFireStations) {
      await _addFireStationMarkers();
    }
  }

  Future<void> _addMarkers() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      log('MapboxMap or PointAnnotationManager not initialized');
      return;
    }

    final provider = context.read<IncidentsProvider>();
    provider.clearMarkers();
    _annotationIncidentMap.clear();

    final Map<String, MbxImage> imageCache = {};
    for (Incident incident in provider.incidents) {
      // Use intelligent icon resolver to get SVG path
      final symbolImage = getIconForSymbolCode(incident.symbolCode ?? '');
      if (symbolImage.isEmpty) {
        log('Invalid marker image for symbolCode: ${incident.symbolCode}');
        continue;
      }

      try {
        final mbxImage = await _loadMbxImage(symbolImage);
        final imageId = 'marker_${incident.symbolCode}_${incident.hashCode}';
        imageCache[imageId] = mbxImage;
        log('Loaded image for ${incident.symbolCode}: ${mbxImage.data.length} bytes');
      } catch (e) {
        log('Error loading image for ${incident.symbolCode}: $e');
        continue;
      }
    }

    // Step 2: Add all images to the style
    for (var entry in imageCache.entries) {
      try {
        await _mapboxMap!.style.addStyleImage(
          entry.key,
          1.0,
          entry.value,
          false,
          [],
          [],
          null,
        );
        log('Added style image: ${entry.key}');
      } catch (e) {
        log('Error adding style image ${entry.key}: $e');
      }
    }

    // Step 3: Create annotations
    for (Incident incident in provider.incidents) {
      // Use intelligent icon resolver to get SVG path
      final symbolImage = getIconForSymbolCode(incident.symbolCode ?? '');
      if (symbolImage.isEmpty) {
        continue;
      }

      try {
        final imageId = 'marker_${incident.symbolCode}_${incident.hashCode}';
        if (!imageCache.containsKey(imageId)) {
          log('Image not cached for ${incident.symbolCode}, skipping annotation');
          continue;
        }
      final mbxImage = imageCache[imageId]!;
final scaleFactor = 30 / mbxImage.width; 
        final pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              incident.latLng.longitude,
              incident.latLng.latitude,
            ),
          ),
          iconImage: imageId,
          iconSize:scaleFactor
        );

        // Create annotation and get the generated ID
        final annotation = await _pointAnnotationManager!.create(pointAnnotationOptions);
        _annotationIncidentMap[annotation.id] = incident;
        log('Marker added for incident with symbolCode: ${incident.symbolCode}, ID: ${annotation.id}');
      } catch (e) {
        log('Error adding marker for ${incident.symbolCode}: $e');
      }
    }

    // Add click listener
    _pointAnnotationManager!.addOnPointAnnotationClickListener(
      PointAnnotationClickListener(
        onClickCallback: (annotation) async {
          log('Marker tapped with ID: ${annotation.id}');
          final incident = _annotationIncidentMap[annotation.id];
          if (incident != null && _mapboxMap != null) {
            log('Moving camera to incident: ${incident.symbolCode} at ${incident.latLng}');
            await _mapboxMap!.setCamera(
              CameraOptions(
                center: Point(
                  coordinates: Position(
                    incident.latLng.longitude,
                    incident.latLng.latitude,
                  ),
                ),
                zoom: 10.0, 
              ),
            );
            showMarkerInfoSheet(incident);
            log('Showing marker info sheet for ${incident.symbolCode}');
          } else {
            log('No incident found for ID: ${annotation.id} or MapboxMap is null');
          }
          return true;
        },
      ),
    );
  }

 Future<MbxImage> _loadMbxImage(String assetPath) async {
  try {
    // For now, use PNG fallback - skip SVG rendering due to API complexity
    // Convert SVG paths to PNG fallback
    if (assetPath.toLowerCase().endsWith('.svg')) {
      // Use a default icon for now
      assetPath = 'assets/images/fire-station.png';
      log('SVG rendering not yet implemented, using PNG fallback: $assetPath');
    }

    // Handle PNG/JPG images
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    // Decode image
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image: $assetPath');
    }

    final resized = img.copyResize(image, width: 50, height: 50);

    return MbxImage(
      width: resized.width,
      height: resized.height,
      data: Uint8List.fromList(img.encodePng(resized)),
    );
  } catch (e) {
    log('Error loading MbxImage for $assetPath: $e');
    rethrow;
  }
}

  /// Add fire station markers to the map
  Future<void> _addFireStationMarkers() async {
    if (_mapboxMap == null || _fireStationAnnotationManager == null) {
      return;
    }

    final provider = context.read<IncidentsProvider>();
    if (provider.fireStations.isEmpty) {
      return;
    }

    _annotationFireStationMap.clear();

    try {
      // Load fire station icon
      final mbxImage = await _loadMbxImage('assets/images/png/fire-station.png');
      const imageId = 'fire_station_icon';

      // Add image to style
      await _mapboxMap!.style.addStyleImage(
        imageId,
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );

      // Create annotations for each fire station
      for (FireStation station in provider.fireStations) {
        try {
          // Use the station ID directly - it contains the complete identifier (e.g., "606", "606T")
          // This matches how ArcGIS displays station numbers with their suffixes
          String stationNumber = station.id;

          // Reduce icon size by 50% (15 instead of 30)
          final scaleFactor = 15 / mbxImage.width;
          final pointAnnotationOptions = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                station.lng,
                station.lat,
              ),
            ),
            iconImage: imageId,
            iconSize: scaleFactor,
            textField: stationNumber, // Display complete station identifier (e.g., "606", "606T")
            textSize: 11.0, // Slightly larger to appear bolder
            textColor: Colors.black.value,
            textOffset: [0.0, 1.5], // Position text below icon
            textHaloColor: Colors.white.value,
            textHaloWidth: 1.5, // Thicker halo for bolder appearance
          );

          final annotation = await _fireStationAnnotationManager!.create(pointAnnotationOptions);
          _annotationFireStationMap[annotation.id] = station;
        } catch (e) {
          log('Error adding fire station marker for ${station.name}: $e');
        }
      }

      // Add click listener for fire station markers
      _fireStationAnnotationManager!.addOnPointAnnotationClickListener(
        PointAnnotationClickListener(
          onClickCallback: (annotation) async {
            log('Fire station marker tapped with ID: ${annotation.id}');
            final station = _annotationFireStationMap[annotation.id];
            if (station != null && _mapboxMap != null) {
              log('Moving camera to fire station: ${station.name} at (${station.lat}, ${station.lng})');
              await _mapboxMap!.setCamera(
                CameraOptions(
                  center: Point(
                    coordinates: Position(
                      station.lng,
                      station.lat,
                    ),
                  ),
                  zoom: 14.0,
                ),
              );
              _showFireStationInfo(station);
              log('Showing fire station info sheet for ${station.name}');
            } else {
              log('No fire station found for ID: ${annotation.id} or MapboxMap is null');
            }
            return true;
          },
        ),
      );
    } catch (e, stackTrace) {
      log('Error adding fire station markers: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Remove fire station markers from the map
  Future<void> _removeFireStationMarkers() async {
    if (_fireStationAnnotationManager == null) return;

    try {
      await _fireStationAnnotationManager!.deleteAll();
      _annotationFireStationMap.clear();
    } catch (e) {
      log('Error removing fire station markers: $e');
    }
  }

  /// Show fire station information
  void _showFireStationInfo(FireStation station) {
    // Extract station number from STATION field or name
    String? stationNumber;

    // First try to get it from the id field (Phoenix Fire uses STATION field like "ST01")
    if (station.id.startsWith('ST') || station.id.startsWith('st')) {
      stationNumber = station.id.substring(2); // Remove "ST" prefix
    } else if (RegExp(r'^\d+$').hasMatch(station.id)) {
      // If id is just numbers, use it directly
      stationNumber = station.id;
    } else {
      // Fallback: Extract from name (e.g., "Phoenix Fire Department Station 13" -> "13")
      final numberMatch = RegExp(r'Station\s+#?(\d+)', caseSensitive: false).firstMatch(station.name);
      if (numberMatch != null) {
        stationNumber = numberMatch.group(1);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                if (stationNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Station #$stationNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    station.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (station.address != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 20, color: isDark ? Colors.grey[400] : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      station.address!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.map, size: 20, color: isDark ? Colors.grey[400] : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${station.lat.toStringAsFixed(6)}, ${station.lng.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PointAnnotationClickListener implements OnPointAnnotationClickListener {
  final Future<bool> Function(PointAnnotation) onClickCallback;

  PointAnnotationClickListener({required this.onClickCallback});

  @override
  Future<bool> onPointAnnotationClick(PointAnnotation annotation) {
    return onClickCallback(annotation);
  }
  

}


// import 'dart:developer';
// import 'package:az_incident_alert/models/incident_model.dart';
// import 'package:az_incident_alert/providers/incidents_provider.dart';
// import 'package:az_incident_alert/utils/app_constants.dart';
// import 'package:az_incident_alert/widgets/marker_sheet.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';

// class ESRIMapWidget extends StatefulWidget {
//   const ESRIMapWidget({super.key, this.initialLatLng});

//   final LatLng? initialLatLng;

//   @override
//   State<ESRIMapWidget> createState() => _ESRIMapWidgetState();
// }

// class _ESRIMapWidgetState extends State<ESRIMapWidget> {
//   final MapController _mapController = MapController();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     log('opend esri map for: ${widget.initialLatLng}');
//     return Consumer<IncidentsProvider>(
//       builder: (context, provider, _) {
//         _addMarkers();
//         log('map type: ${provider.mapType}');
//         return FlutterMap(
//           mapController: _mapController,
//           options: MapOptions(
//             initialCenter: widget.initialLatLng ?? kPhoenixLatLng,
//             initialZoom: widget.initialLatLng == kPhoenixLatLng ? 10.0 : 16.0,
//             interactionOptions: const InteractionOptions(
//               pinchZoomWinGestures: MultiFingerGesture.pinchZoom,
//             ),
//           ),
//           children: [
//             TileLayer(
//               urlTemplate: provider.mapType == kNormalMapType
//                   ? 'https://{s}.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}'
//                   : 'https://{s}.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
//               subdomains: const ['server', 'services'],
//             ),
//             if (provider.mapType == kSatelliteMapType)
//               TileLayer(
//                 urlTemplate:
//                     'https://{s}.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
//                 subdomains: const ['server', 'services'],
//               ),
//             MarkerLayer(
//               markers: provider.markers,
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _addMarkers() {
//     context.read<IncidentsProvider>().clearMarkers();

//     for (Incident incident in context.read<IncidentsProvider>().incidents) {
//       log('symbol for marker: ${kSymbolCodesImages[incident.symbolCode]}');
//       context.read<IncidentsProvider>().addMarker(
//             Marker(
//               point:
//                   LatLng(incident.latLng.latitude, incident.latLng.longitude),
//               child: InkWell(
//                 onTap: () {
//                   _mapController.move(incident.latLng, 17);
//                   showMarkerInfoSheet(incident);
//                 },
//                 child: Image.asset(
//                   kSymbolCodesImages[incident.symbolCode] ?? '',
//                   height: 35,
//                 ),
//               ),
//             ),
//           );
//       log('Marker added!');
//     }
//   }
// }
