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

  /// Factory constructor to create FireStation from JSON response
  /// Supports Overpass API, Google Places API, Phoenix Fire FeatureServer, Phoenix Fire MapServer GeoJSON, and USGS National Map
  factory FireStation.fromJson(Map<String, dynamic> json) {
    // Check if this is an Esri JSON Feature (Phoenix Fire FeatureServer or USGS)
    if (json['attributes'] != null && json['geometry'] != null) {
      // Try to differentiate between Phoenix Fire and USGS
      final attributes = json['attributes'] as Map<String, dynamic>;
      if (attributes.containsKey('STATION')) {
        // Phoenix Fire has STATION field
        return FireStation.fromPhoenixFireEsriJson(json);
      } else if (attributes.containsKey('NAME') && attributes.containsKey('STATE')) {
        // USGS has NAME and STATE fields
        return FireStation.fromUSGSEsriJson(json);
      }
      // Default to Phoenix Fire format for backwards compatibility
      return FireStation.fromPhoenixFireEsriJson(json);
    }

    // Check if this is a GeoJSON Feature (Phoenix Fire MapServer)
    if (json['type'] == 'Feature' && json['geometry'] != null && json['properties'] != null) {
      return FireStation.fromPhoenixFireGeoJson(json);
    }

    // Check if this is a Google Places API response
    if (json['place_id'] != null && json['geometry'] != null) {
      return FireStation.fromGooglePlaces(json);
    }

    // Otherwise, handle Overpass API response
    return FireStation.fromOverpass(json);
  }

  /// Factory constructor for Phoenix Fire FeatureServer Esri JSON response
  factory FireStation.fromPhoenixFireEsriJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;

    // Esri JSON geometry: {x: longitude, y: latitude}
    // Coordinates are in WGS84 format when outSR=4326 is used
    final lng = (geometry['x'] as num).toDouble();
    final lat = (geometry['y'] as num).toDouble();

    // Build name from station number
    final stationNum = attributes['STATION']?.toString() ?? '';
    String name = stationNum.isNotEmpty ? 'Fire Station $stationNum' : 'Fire Station';

    // Build full address including city
    String? fullAddress = attributes['ADDRESS'] as String?;
    if (fullAddress != null && attributes['CITY'] != null) {
      final cityCode = attributes['CITY'] as String;
      final cityName = _expandCityCode(cityCode);
      fullAddress = '$fullAddress, $cityName';
    }

    return FireStation(
      id: stationNum.isNotEmpty ? stationNum : attributes['OBJECTID']?.toString() ?? 'unknown',
      name: name,
      lat: lat,
      lng: lng,
      address: fullAddress,
      tags: {
        'source': 'phoenix_fire_featureserver',
        'station': attributes['STATION'],
        'city': attributes['CITY'],
        'proposed': attributes['PROPOSED'],
        'private': attributes['PRIVATE'],
        'objectid': attributes['OBJECTID'],
        'station_sort': attributes['StationSort'],
      },
    );
  }

  /// Helper to expand city codes to full city names
  static String _expandCityCode(String code) {
    const cityMap = {
      'PHX': 'Phoenix',
      'SCT': 'Scottsdale',
      'TMP': 'Tempe',
      'CHA': 'Chandler',
      'GLN': 'Glendale',
      'PEO': 'Peoria',
      'AVO': 'Avondale',
      'SUR': 'Surprise',
      'BUC': 'Buckeye',
      'SUN': 'Sun City',
      'SCW': 'Scottsdale West',
      'HRQ': 'Harquahala',
      'BUV': 'Buckeye Valley',
      'GDY': 'Goodyear',
      'MRC': 'Maricopa',
      'BCC': 'Black Canyon City',
      'TOL': 'Tolleson',
      'MAR': 'Maryvale',
      'GUA': 'Guadalupe',
      'SLK': 'Sun Lakes',
      'CAV': 'Cave Creek',
      'TON': 'Tonopah',
      'ELM': 'El Mirage',
      'DSY': 'Daisy Mountain',
      'PDV': 'Paradise Valley',
      'LAV': 'Laveen',
    };
    return cityMap[code] ?? code;
  }

  /// Factory constructor for Phoenix Fire MapServer GeoJSON response
  factory FireStation.fromPhoenixFireGeoJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    // GeoJSON coordinates are [longitude, latitude]
    final lng = (coordinates[0] as num).toDouble();
    final lat = (coordinates[1] as num).toDouble();

    // Build name from StationSort or construct from STATION and ADDRESS
    String name = 'Fire Station';
    if (properties['StationSort'] != null && (properties['StationSort'] as String).isNotEmpty) {
      name = properties['StationSort'] as String;
    } else if (properties['STATION'] != null) {
      name = 'Phoenix Fire Station ${properties['STATION']}';
    }

    // Build full address including city if available
    String? fullAddress = properties['ADDRESS'] as String?;
    if (fullAddress != null && properties['CITY'] != null) {
      fullAddress = '$fullAddress, ${properties['CITY']}';
    }

    return FireStation(
      id: properties['STATION']?.toString() ?? properties['OBJECTID']?.toString() ?? 'unknown',
      name: name,
      lat: lat,
      lng: lng,
      address: fullAddress,
      tags: {
        'source': 'phoenix_fire',
        'station': properties['STATION'],
        'city': properties['CITY'],
        'proposed': properties['PROPOSED'],
        'private': properties['PRIVATE'],
        'objectid': properties['OBJECTID'],
      },
    );
  }

  /// Factory constructor for USGS National Map Esri JSON response
  factory FireStation.fromUSGSEsriJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;

    // Esri JSON geometry: {x: longitude, y: latitude}
    // Note: USGS returns coordinates in requested projection (4326 = WGS84)
    final lng = (geometry['x'] as num).toDouble();
    final lat = (geometry['y'] as num).toDouble();

    // Get station name from NAME field
    String name = attributes['NAME']?.toString() ?? 'Fire Station';

    // Extract station number if present in name (e.g., "Station 201" -> "201")
    String? stationNumber;
    final stationMatch = RegExp(r'Station\s+(\d+\w*)', caseSensitive: false).firstMatch(name);
    if (stationMatch != null) {
      stationNumber = stationMatch.group(1);
    }

    // Build full address including city and state
    String? fullAddress = attributes['ADDRESS'] as String?;
    final city = attributes['CITY'] as String?;
    final state = attributes['STATE'] as String?;
    final zipcode = attributes['ZIPCODE'] as String?;

    if (fullAddress != null) {
      final parts = <String>[fullAddress];
      if (city != null && city.isNotEmpty) parts.add(city);
      if (state != null && state.isNotEmpty) parts.add(state);
      if (zipcode != null && zipcode.isNotEmpty) parts.add(zipcode);
      fullAddress = parts.join(', ');
    }

    return FireStation(
      id: stationNumber ?? attributes['OBJECTID']?.toString() ?? 'unknown',
      name: name,
      lat: lat,
      lng: lng,
      address: fullAddress,
      tags: {
        'source': 'usgs_national_map',
        'objectid': attributes['OBJECTID'],
        'city': city,
        'state': state,
        'zipcode': zipcode,
        'fcode': attributes['FCODE'],
        'gnis_id': attributes['GNIS_ID'],
        'admintype': attributes['ADMINTYPE'],
      },
    );
  }

  /// Factory constructor for Google Places API response
  factory FireStation.fromGooglePlaces(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;

    return FireStation(
      id: json['place_id'] as String,
      name: json['name'] as String? ?? 'Fire Station',
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
      address: json['formatted_address'] as String?,
      tags: {
        'source': 'google_places',
        'types': json['types'],
        'business_status': json['business_status'],
      },
    );
  }

  /// Factory constructor for Overpass API response
  factory FireStation.fromOverpass(Map<String, dynamic> json) {
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
