import 'dart:developer';
import 'package:az_incident_alert/models/fire_station_model.dart';
import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:dio/dio.dart';

class FireStationService {
  static final FireStationService _instance = FireStationService._();
  static FireStationService get instance => _instance;

  FireStationService._();

  final _overpassApi = 'https://overpass-api.de/api/interpreter';

  /// Fetch fire stations in Phoenix, Arizona using Overpass API
  Future<List<FireStation>> getFireStations() async {
    try {

      // Overpass QL query for fire stations in Phoenix using bounding box
      // Phoenix bounding box: South: 33.287, West: -112.324, North: 33.927, East: -111.925
      const String query = '''
[out:json][timeout:25];
(
  node["amenity"="fire_station"](33.287,-112.324,33.927,-111.925);
  way["amenity"="fire_station"](33.287,-112.324,33.927,-111.925);
  relation["amenity"="fire_station"](33.287,-112.324,33.927,-111.925);
);
out center;
      ''';

      // Create a separate Dio instance for Overpass API
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      // Make POST request to Overpass API
      final response = await dio.post(
        _overpassApi,
        data: {'data': query},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];

        // Parse fire stations from response and deduplicate by ID
        final fireStationsMap = <String, FireStation>{};
        for (var element in elements) {
          final station = FireStation.fromJson(element as Map<String, dynamic>);
          if (station.lat != 0.0 && station.lng != 0.0) {
            if (!fireStationsMap.containsKey(station.id)) {
              fireStationsMap[station.id] = station;
            }
          }
        }
        final fireStations = fireStationsMap.values.toList();

        return fireStations;
      } else {
        log('[FireStationService] Error: Status code ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      log('[FireStationService] Error fetching fire stations: $e');
      log('[FireStationService] Stack trace: $stackTrace');
      return [];
    }
  }
}
