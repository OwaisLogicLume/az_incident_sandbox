import 'dart:developer';
import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService _instance = FirebaseService._();

  static FirebaseService get instance => _instance;

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  late DocumentReference? currentUser;

  Future<QuerySnapshot> getCurrentUser() async {
    return await usersCollection
        .where(kDeviceIdKey, isEqualTo: SharedPrefs.instance.deviceId)
        .get();
  }

  Future<void> init() async {
    final currentUserSnapShot = await getCurrentUser();

    if (currentUserSnapShot.docs.isEmpty) {
      currentUser = await addUser([]);
    } else {
      currentUser = currentUserSnapShot.docs.single.reference;
      await currentUser?.update({
        kFCMKey: SharedPrefs.instance.fcm,
      });
      log('Updated user\'s FCM token');
      log('User with the same device ID already exists.');
      currentUser = currentUserSnapShot.docs.single.reference;
    }
  }

  Future<DocumentReference?> addUser(List<int> stations) async {
    try {
      return await usersCollection.add({
        kDeviceIdKey: SharedPrefs.instance.deviceId,
        kStationsKey: stations,
        kFCMKey: SharedPrefs.instance.fcm,
        kAlertedIncidentsKey: [],
      }).then((value) {
        log('User added successfully: ${value.id}');
        return value;
      });
    } catch (e) {
      log('Error adding user: $e');
      return null;
    }
  }

  Future<void> removeUser() async {
    try {
      if (currentUser == null) {
        log('User not found.');
        return;
      }

      await currentUser?.delete();
      log('User removed successfully.');
    } catch (e) {
      log('Error removing user: $e');
    }
  }

  Future<List<String>> getUsersStations() async {
    try {
      if (currentUser == null) {
        log('User not found.');
        return [];
      }

      final userDocSnapShot = await currentUser?.get();

      log('User ID while fetching stations: ${userDocSnapShot?.get(kDeviceIdKey)}');
      log('Saved key from prefs: ${SharedPrefs.instance.deviceId}');

      final List<String> stations =
          (await userDocSnapShot?.get(kStationsKey) as List<dynamic>? ?? [])
              .cast<String>();

      log('Stations from Firebase: $stations');

      return stations;
    } catch (e) {
      log('Error getting stations: $e');
      return <String>[];
    }
  }

  Future<void> addStation(String station) async {
    try {
      final List<String> stations = await getUsersStations();

      stations
        ..add(station)
        ..sort(Utils().stationSortCallback);

      log('New stations: $stations');

      await currentUser?.update({
        kStationsKey: stations,
      });
      log('Station added successfully: $station');
    } catch (e) {
      log('Error adding station: $e');
    }
  }

  Future<void> removeStation(String station) async {
    try {
      if (currentUser == null) {
        log('User not found.');
        return;
      }

      await currentUser?.update({
        kStationsKey: FieldValue.arrayRemove([station]),
      });
      log('Station removed successfully: $station');
    } catch (e) {
      log('Error removing station: $e');
    }
  }

  Future<void> saveIncidentsToFirebase(List<Incident> incidents) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref("incidents");
      final Map<String, dynamic> incidentMap = {};

      for (var incident in incidents) {
        final key = incident.objectid.toString();
        try {
          incidentMap[key] = incident.toJson();
        } catch (e, s) {
          log('Error serializing incident $key: $e');
          log('Stack trace: $s');
          rethrow;
        }
      }

      await dbRef.set(incidentMap);
      log('Saved ${incidentMap.length} incidents to Firebase');
    } catch (e, s) {
      log('Error saving incidents to Firebase: $e');
      log('Stack trace: $s');
      rethrow;
    }
  }

  Future<List<Incident>> getIncidentsFromFirebase() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref("incidents");
      final snapshot = await dbRef.get();

      final List<Incident> result = [];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var entry in data.entries) {
          try {
            final map = Map<String, dynamic>.from(entry.value as Map);
            final geometry = Map<String, dynamic>.from(map['geometry'] ?? {});
            final incident = Incident.fromJson(map, geometry);
            await incident.getCordinatesFromGeometry();
            result.add(incident);
          } catch (e, s) {
            log('Error parsing incident from Firebase (key: ${entry.key}): $e');
            log('Stack trace: $s');
            rethrow;
          }
        }
      }
      log('Retrieved ${result.length} incidents from Firebase');
      return result;
    } catch (e, s) {
      log('Error retrieving incidents from Firebase: $e');
      log('Stack trace: $s');
      rethrow;
    }
  }

  // Fetch transformed coordinates from Realtime Database
  Future<List<Map<String, dynamic>>> getTransformedCoordinates() async {
    try {
      final DatabaseEvent event = await database.child('transformed_coordinates').once();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        log('No transformed coordinates found in Firebase');
        return [];
      }

      final List<Map<String, dynamic>> coordinates = [];
      data.forEach((key, value) {
        coordinates.add({
          'key': key,
          'latitude': value['latitude'],
          'longitude': value['longitude'],
          'originalX': value['originalX'],
          'originalY': value['originalY'],
          'timestamp': value['timestamp'],
        });
      });

      log('Fetched ${coordinates.length} transformed coordinates from Firebase');
      return coordinates;
    } catch (e) {
      log('Error getting transformed coordinates from Firebase: $e');
      return [];
    }
  }

  // Call Cloud Function to transform coordinates
  Future<Map<String, dynamic>?> transformCoordinates({
    required double x,
    required double y,
    required int sSrs,
    required int tSrs,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('transformCoordinates');
      final result = await callable.call({
        'x': x,
        'y': y,
        's_srs': sSrs,
        't_srs': tSrs,
      });
      log('Transformed coordinates: ${result.data}');
      return result.data as Map<String, dynamic>?;
    } catch (e) {
      log('Error transforming coordinates: $e');
      return null;
    }
  }
}