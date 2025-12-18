import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

enum IncidentApiSource {
  phoenixFire,  // Phoenix Fire Department ESRI API
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
    print('flutter: [IncidentService] 🔄 Fetching incidents from Phoenix Fire API...');
    _lastApiCall = DateTime.now();

    try {
      // Fetch from Phoenix Fire API
      final data = await _fetchFromPhoenixFire();

      if (data != null && data['features'] != null) {
        final features = data['features'] as List;
        print('flutter: [IncidentService] ✅ Phoenix Fire: ${features.length} incidents');

        // Log each incident with details
        for (var feature in features) {
          final incidentId = feature['attributes']?['Incident']?.toString();
          final location = feature['attributes']?['GenLocInfo'] ?? 'Unknown location';
          final nature = feature['attributes']?['Nature'] ?? 'Unknown';
          if (incidentId != null) {
            print('flutter: [IncidentService] 📍 $incidentId - $nature at $location');
          }
        }

        print('flutter: [IncidentService] 📊 Total incidents: ${features.length}');
      }

      // Return in the same format as original API
      return data;
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
