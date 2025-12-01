import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';
import 'package:az_incident_alert/models/incident_model.dart';
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
  final Map<String, Incident> _annotationIncidentMap = {};

  @override
  Widget build(BuildContext context) {
    final initialLatLng = widget.initialLatLng ?? kPhoenixLatLng;
    
    

    return Consumer<IncidentsProvider>(
      builder: (context, provider, _) {
         final styleUri = _getStyleUri(provider);
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
    await _addMarkers();
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
