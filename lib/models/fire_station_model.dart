import 'package:latlong2/latlong.dart';

class FireStation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final Map<String, dynamic>? tags;

  FireStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.tags,
  });

  /// Factory constructor to create FireStation from Overpass API JSON response
  factory FireStation.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    // Get coordinates - handle both node and way (with center) responses
    double latitude;
    double longitude;

    if (json['type'] == 'node') {
      latitude = (json['lat'] as num).toDouble();
      longitude = (json['lon'] as num).toDouble();
    } else if (json['type'] == 'way' && json['center'] != null) {
      latitude = (json['center']['lat'] as num).toDouble();
      longitude = (json['center']['lon'] as num).toDouble();
    } else {
      latitude = 0.0;
      longitude = 0.0;
    }

    return FireStation(
      id: json['id'].toString(),
      name: tags['name'] ?? 'Fire Station',
      lat: latitude,
      lng: longitude,
      address: tags['addr:full'] ?? tags['addr:street'],
      tags: tags,
    );
  }

  /// Convert to LatLng for map display
  LatLng toLatLng() {
    return LatLng(lat, lng);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'address': address,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'FireStation(id: $id, name: $name, lat: $lat, lng: $lng, address: $address)';
  }
}
