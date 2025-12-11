import 'dart:developer';
import 'package:az_incident_alert/models/fire_station_model.dart';
import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:dio/dio.dart';

enum FireStationFilter {
  allRegional,  // WHERE 1=1 - All regional dispatch stations (152)
  phoenixOnly,  // WHERE CITY='PHX' - Phoenix Fire Department only (61)
}

class FireStationService {
  static final FireStationService _instance = FireStationService._();
  static FireStationService get instance => _instance;

  FireStationService._();

  // Phoenix Fire Department FeatureServer API
  final _phoenixFireApi = 'https://maps.phoenix.gov/phxfire/rest/services/SharedResources/PFD_Regional_Dispatch_Fire_Stations/FeatureServer/0/query';

  /// Fetch fire stations from Phoenix Fire Department FeatureServer
  ///
  /// [filter] - Filter type (allRegional or phoenixOnly)
  /// [onPageFetched] - Optional callback invoked when data is fetched
  Future<List<FireStation>> getFireStations({
    FireStationFilter filter = FireStationFilter.phoenixOnly,
    Function(List<FireStation>)? onPageFetched,
  }) async {
    try {
      print('[FireStationService] 🚀 Fetching fire stations from Phoenix Fire FeatureServer...');

      // Create Dio instance
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      // Build WHERE clause based on filter
      final whereClause = filter == FireStationFilter.allRegional
          ? "1=1"  // All regional dispatch stations
          : "CITY='PHX'";  // Phoenix Fire Department only

      final filterDesc = filter == FireStationFilter.allRegional
          ? 'all regional stations'
          : 'Phoenix Fire Department only';
      print('[FireStationService] 📝 Query filter: $whereClause ($filterDesc)');

      // Make GET request to Phoenix Fire FeatureServer
      final response = await dio.get(
        _phoenixFireApi,
        queryParameters: {
          'where': whereClause,
          'outFields': '*',  // Get all fields
          'returnGeometry': 'true',
          'outSR': '4326',   // WGS84 coordinate system (lat/lng)
          'f': 'json',       // Esri JSON format
        },
      );

      print('[FireStationService] 📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        print('[FireStationService] 📊 Found ${features.length} fire stations');

        final fireStations = <FireStation>[];

        for (var feature in features) {
          try {
            final station = FireStation.fromPhoenixFireEsriJson(feature as Map<String, dynamic>);
            fireStations.add(station);
            print('[FireStationService] ✅ Parsed: ${station.name} at (${station.lat}, ${station.lng})');
          } catch (e) {
            print('[FireStationService] ⚠️ Error parsing station: $e');
          }
        }

        // Call the callback if provided
        if (onPageFetched != null && fireStations.isNotEmpty) {
          onPageFetched(fireStations);
        }

        print('[FireStationService] ✅ Returning ${fireStations.length} fire stations');
        return fireStations;
      } else {
        print('[FireStationService] ❌ Error: Status code ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[FireStationService] ❌ Error fetching fire stations: $e');
      print('[FireStationService] Stack trace: $stackTrace');
      return [];
    }
  }
}
