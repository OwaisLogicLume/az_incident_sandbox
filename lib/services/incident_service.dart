import 'dart:developer';

import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:latlong2/latlong.dart';

abstract class BaseIncidentService {
  Future<dynamic> getIncidents();
  Future<LatLng> getLatLng(double x, double y);
}

class IncidentService implements BaseIncidentService {
  final _api = BaseRepository.instance.dio;

  IncidentService._();

  static final IncidentService _instance = IncidentService._();

  static IncidentService get instance => _instance;

  @override
  Future getIncidents() async {
    final res = await _api.get(
      '/phxfire/rest/services/Active_Incidents__Public/MapServer/0/query?f=json&cacheHint=true&resultOffset=0&resultRecordCount=100&where=1%3D1&orderByFields=Incident%20DESC&outFields=*&returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPoint',
    );
    return res.data;
  
  }

  @override
  Future<LatLng> getLatLng(double x, double y) async {
    // final url = 'https://epsg.io/trans?x=$x&y=$y&s_srs=2868&t_srs=4326';

    final url =
        'https://api.maptiler.com/coordinates/transform/$x,$y.json?s_srs=2868&t_srs=4326&key=$kMapTilerKey';
    final resp = await _api.getUri(Uri.parse(url));
    log("lat lng from API => ${resp.data}");
    final latLngMap = resp.data['results'][0];
    return LatLng(latLngMap['y'], latLngMap['x']);
  }
}
