import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

enum IncidentApiSource {
  phoenixFire,  // Phoenix Fire Department ESRI API
  phxsdr,       // phxsdr.com API
}

abstract class BaseIncidentService {
  Future<dynamic> getIncidents();
  Future<LatLng> getLatLng(double x, double y);
}

class IncidentService implements BaseIncidentService {
  final _api = BaseRepository.instance.dio;

  IncidentService._();

  static final IncidentService _instance = IncidentService._();

  static IncidentService get instance => _instance;

  DateTime? _lastApiCall;

  @override
  Future getIncidents() async {
    print('flutter: [IncidentService] 🔄 Fetching from BOTH APIs...');
    _lastApiCall = DateTime.now();

    try {
      // Fetch from both APIs in parallel
      final results = await Future.wait([
        _fetchFromPhoenixFire(),
        _fetchFromPhxsdr(),
      ], eagerError: false);

      final phoenixData = results[0];
      final phxsdrData = results[1];

      // Merge features from both sources and tag with API source
      final allFeatures = <dynamic>[];

      if (phoenixData != null && phoenixData['features'] != null) {
        final phoenixFeatures = phoenixData['features'] as List;
        // Tag each feature with its source
        for (var feature in phoenixFeatures) {
          feature['_apiSource'] = 'Phoenix Fire';
          allFeatures.add(feature);
        }
        print('flutter: [IncidentService] ✅ Phoenix Fire: ${phoenixFeatures.length} incidents');
      }

      if (phxsdrData != null && phxsdrData['features'] != null) {
        final phxsdrFeatures = phxsdrData['features'] as List;
        // Tag each feature with its source
        for (var feature in phxsdrFeatures) {
          feature['_apiSource'] = 'phxsdr';
          allFeatures.add(feature);
        }
        print('flutter: [IncidentService] ✅ phxsdr: ${phxsdrFeatures.length} incidents');
      }

      // Remove duplicates based on Incident ID
      final Map<String, dynamic> uniqueIncidents = {};
      int phoenixCount = 0;
      int phxsdrCount = 0;

      for (var feature in allFeatures) {
        final incidentId = feature['attributes']?['Incident']?.toString();
        if (incidentId != null && !uniqueIncidents.containsKey(incidentId)) {
          uniqueIncidents[incidentId] = feature;
          final apiSource = feature['_apiSource'];

          // Count by source
          if (apiSource == 'Phoenix Fire') {
            phoenixCount++;
          } else if (apiSource == 'phxsdr') {
            phxsdrCount++;
          }

          // Log each unique incident with its source
          final location = feature['attributes']?['GenLocInfo'] ?? 'Unknown location';
          final nature = feature['attributes']?['Nature'] ?? 'Unknown';
          print('flutter: [IncidentService] 📍 [$apiSource] $incidentId - $nature at $location');
        }
      }

      print('flutter: [IncidentService] 📊 Total unique incidents: ${uniqueIncidents.length}');
      print('flutter: [IncidentService] 📊 Breakdown: Phoenix Fire=$phoenixCount, phxsdr=$phxsdrCount');

      // Return in the same format as original API
      return {
        'features': uniqueIncidents.values.toList(),
      };
    } catch (e) {
      print('flutter: [IncidentService] ❌ Error fetching incidents: $e');
      rethrow;
    }
  }

  /// Fetch from Phoenix Fire Department ESRI API
  Future<dynamic> _fetchFromPhoenixFire() async {
    try {
      final res = await _api.get(kPhoenixFireApiPath);
      return res.data;
    } catch (e) {
      print('flutter: [IncidentService] ⚠️ Phoenix Fire API error: $e');
      return {'features': []};  // Return empty on error
    }
  }

  /// Fetch from phxsdr.com API
  Future<dynamic> _fetchFromPhxsdr() async {
    try {
      // phxsdr API uses absolute URL, need Dio instance without base URL
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final res = await dio.get(kPhxsdrApiUrl);
      // phxsdr API response format matches Phoenix Fire (Esri JSON with features array)
      return res.data;
    } catch (e) {
      print('flutter: [IncidentService] ⚠️ phxsdr API error: $e');
      return {'features': []};  // Return empty on error
    }
  }

  /// Get last API call timestamp
  DateTime? get lastApiCall => _lastApiCall;

  @override
  Future<LatLng> getLatLng(double x, double y) async {
    // final url = 'https://epsg.io/trans?x=$x&y=$y&s_srs=2868&t_srs=4326';

    final url =
        'https://api.maptiler.com/coordinates/transform/$x,$y.json?s_srs=2868&t_srs=4326&key=$kMapTilerKey';
    final resp = await _api.getUri(Uri.parse(url));
    print("flutter: lat lng from API => ${resp.data}");
    final latLngMap = resp.data['results'][0];
    return LatLng(latLngMap['y'], latLngMap['x']);
  }
}
