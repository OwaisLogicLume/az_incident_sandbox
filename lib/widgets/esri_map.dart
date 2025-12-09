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
         print('[MapWidget] Building map with styleUri: $styleUri');

         // Update fire station markers when showFireStations changes
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (provider.showFireStations && _fireStationAnnotationManager != null) {
             _addFireStationMarkers();
           } else if (!provider.showFireStations && _fireStationAnnotationManager != null) {
             _removeFireStationMarkers();
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
  print('[MapWidget] Getting style URI for mapType: ${provider.mapType}');
  if (provider.mapType == KDayMapType) {
    // Note: This Mapbox style ID is actually a light/day style despite the ID
    print('[MapWidget] Returning DAY style URI: cmb4lpzb800l101sda1ewfx4g');
    return "mapbox://styles/azincidentalert/cmb4lpzb800l101sda1ewfx4g";
  } else if (provider.mapType == KNightMapType) {
    // Note: This Mapbox style ID is actually a dark/night style despite the ID
    print('[MapWidget] Returning NIGHT style URI: cmb4ptheg00ji01qxch9ghb8c');
    return 'mapbox://styles/azincidentalert/cmb4ptheg00ji01qxch9ghb8c';

  } else if (provider.mapType == kSatelliteMapType) {
    print('[MapWidget] Returning SATELLITE style URI');
    return MapboxStyles.SATELLITE_STREETS;
  } else {
    print('[MapWidget] Returning default STREETS style URI');
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
          final scaleFactor = 30 / mbxImage.width;
          final pointAnnotationOptions = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                station.lng,
                station.lat,
              ),
            ),
            iconImage: imageId,
            iconSize: scaleFactor,
          );

          final annotation = await _fireStationAnnotationManager!.create(pointAnnotationOptions);
          _annotationFireStationMap[annotation.id] = station;
        } catch (e) {
          log('Error adding fire station marker for ${station.name}: $e');
        }
      }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      station.address!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.map, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${station.lat.toStringAsFixed(6)}, ${station.lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
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
