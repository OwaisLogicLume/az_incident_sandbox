import 'dart:developer';
import 'package:az_incident_alert/services/incident_service.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:latlong2/latlong.dart';

class Incident {
  int objectid;
  String incident;
  String? nature;
  String? natureDesc;
  String? units;
  String? channel;
  String? symbolCode;
  DateTime? date;
  String? genLocInfo;
  LatLng latLng = kPhoenixLatLng;
  Map<String, dynamic> geometry;

  Incident({
    required this.objectid,
    required this.incident,
    this.nature,
    this.natureDesc,
    this.units,
    this.channel,
    this.symbolCode,
    this.date,
    this.genLocInfo,
    this.geometry = const {},
  });

  Incident copyWith({
    int? objectid,
    String? incident,
    String? nature,
    String? natureDesc,
    List<String>? formattedUnits,
    String? channel,
    String? symbolCode,
    DateTime? date,
    String? genLocInfo,
    Map<String, dynamic>? geometry,
  }) =>
      Incident(
        objectid: objectid ?? this.objectid,
        incident: incident ?? this.incident,
        nature: nature ?? this.nature,
        natureDesc: natureDesc ?? this.natureDesc,
        units: formattedUnits?.join(' ') ?? this.units,
        channel: channel ?? this.channel,
        symbolCode: symbolCode ?? this.symbolCode,
        date: date ?? this.date,
        genLocInfo: genLocInfo ?? this.genLocInfo,
        geometry: geometry ?? this.geometry,
      );

  factory Incident.fromJson(Map<String, dynamic> json, Map<String, dynamic> geometry) {
    log('unitsWithLables => ${json['Units'].toString().split(' ').map((e) => HtmlUnescape().convert(e)).toList()}');
    log('alphanumeric => ${json['Units'].toString().split(' ').map((e) => HtmlUnescape().convert(e)).toList().map((e) => e.split(':').first).toSet()}');

    return Incident(
      objectid: int.tryParse(json["OBJECTID"]?.toString() ?? "0") ?? 0, // Safe parsing with default
      incident: json["Incident"]?.toString() ?? "", // Default for required field
      nature: json["Nature"]?.toString(),
      natureDesc: json["NatureDesc"]?.toString(),
      units: json["Units"]?.toString(),
      channel: json["Channel"]?.toString(),
      symbolCode: json["SymbolCode"]?.toString(),
      date: json["Date"] != null
          ? DateTime.fromMillisecondsSinceEpoch(json["Date"] as int)
          : null,
      genLocInfo: json["GenLocInfo"]?.toString(),
      geometry: geometry,
    );
  }

  // [AM-192: On Scene, E191: On Scene]
  List<String> get unitsWithLables {
    return units
            ?.toString()
            .split(' ')
            .map((e) => HtmlUnescape().convert(e))
            .toList() ??
        [];
  }

  Set<String> get unitAlphanumerics {
    return unitsWithLables.map((e) => e.split(':').first).toSet();
  }

  // [10, 20, 456]
  Set<int> get unitNumbers {
    RegExp regex = RegExp(r'\d+');
    Iterable<Match> matches = regex.allMatches(
      HtmlUnescape().convert(units ?? ''),
    );

    List<int> numbers =
        matches.map((match) => int.parse(match.group(0).toString())).toList();

    return numbers.toSet();
  }

  Map<String, dynamic> toJson() => {
        "objectid": objectid,
        "Incident": incident,
        "Nature": nature,
        "NatureDesc": natureDesc,
        "Units": units,
        "Channel": channel,
        "SymbolCode": symbolCode,
        "date": date?.toIso8601String(),
        "GenLocInfo": genLocInfo,
        "geometry": geometry,
      };

  Future<void> getCordinatesFromGeometry() async {
    try {
      if (geometry['x'] != null && geometry['y'] != null) {
        latLng = await IncidentService.instance
            .getLatLng(geometry['x'], geometry['y']);
        log('getted LatLng from map API: $latLng');
      }
    } catch (e) {
      log('Error while getting lat lng: $e');
    }
  }
}

class Plan {
  final String title;
  final String price;
  final String? subtitle;
  bool isSelected;

  Plan({
    required this.title,
    required this.price,
    this.subtitle,
    required this.isSelected,
  });
} 