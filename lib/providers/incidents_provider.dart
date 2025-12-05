import 'dart:developer';
import 'dart:async'; // Added for Timer

import 'package:az_incident_alert/models/incident_model.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:az_incident_alert/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:az_incident_alert/services/incident_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapThemeType { light, dark, satellite }

class IncidentsProvider extends ChangeNotifier {
  final BaseIncidentService services;

  IncidentsProvider(this.services) {}

  /// Values ///
  bool _isLoading = true;
  bool _isAlertLoading = false;
  bool _showUnitsField = false;
  String _mapType = KDayMapType;
  List<String> _selectedUnits = [];
  String? _selectedCat;
  String _lastDayNightMapType = KDayMapType;
  List<Incident> _incidents = [];
  LatLng _currentLatLng = kPhoenixLatLng;
  final List<Incident> _filteredIncidents = [];
  final List<String> _selectedSymbolCodes = <String>[];
  List<Marker> _markers = [];
  final Map<String, String> _symbolCodes = kSymbolCodesImages;
  MapThemeType _mapThemeType = MapThemeType.light;
  Timer? _pollingTimer; // Timer for periodic API calls
  DateTime? _lastApiCall; // Track last API call time
  static const int _pollingIntervalSeconds = 30; // 30-second polling interval
  bool _isAdminMode = false; // Admin mode for full wildcard access

  MapThemeType get mapThemeType => _mapThemeType;

  Map<String, dynamic> geometry = {};

  /// Getters ///
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get isAlertLoading => _isAlertLoading;
  bool get showUnitsField => _showUnitsField;
  String get lastDayNightMapType => _lastDayNightMapType;
  String get mapType => _mapType;
  List<String> get selectedUnits => _selectedUnits;
  LatLng get currentLatLng => _currentLatLng;
  bool get isFiltersSelected => _selectedSymbolCodes.isNotEmpty;
  String? get selectedCat => _selectedCat;
  List<Incident> get incidents => _incidents;
  List<Incident> get filteredIncidents => _filteredIncidents;
  List<String> get selectedSymbolCodes => _selectedSymbolCodes;
  List<Marker> get markers => _markers;
  Map<String, String> get symbolCodes => _symbolCodes;
  bool get isAdminMode => _isAdminMode;

  /// Methods ///

  setLoading(bool newValue) {
    _isLoading = newValue;
    notifyListeners();
  }

  setAleartLoading(bool newValue) {
    _isAlertLoading = newValue;
    notifyListeners();
  }

  changeShowUnitsField(bool newValue) {
    _showUnitsField = newValue;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _mapType = _isDarkMode ? KNightMapType : KDayMapType;
    notifyListeners();
  }

  void changeMapType(String newType) {
    _mapType = newType;
    if (newType == KDayMapType || newType == KNightMapType) {
      _lastDayNightMapType = newType;
    }
    notifyListeners();
  }

  /// Get auto-detected map type based on current time
  /// Returns Day mode between 6 AM - 6 PM, Night mode between 6 PM - 6 AM
  String getAutoMapType() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 18) {
      return KDayMapType; // 6 AM to 6 PM
    } else {
      return KNightMapType; // 6 PM to 6 AM
    }
  }

  /// Initialize map type based on current time
  /// Called when provider is initialized or app launches
  void initializeMapType() {
    _mapType = getAutoMapType();
    _lastDayNightMapType = _mapType;
    notifyListeners();
  }

  void setMapTheme(MapThemeType type) {
    _mapThemeType = type;
    notifyListeners();
  }

  /// Load admin mode state from SharedPrefs
  void loadAdminMode() {
    _isAdminMode = SharedPrefs.instance.isAdminMode;
    log('Admin mode loaded: $_isAdminMode');
    notifyListeners();
  }

  /// Toggle admin mode and persist to SharedPrefs
  Future<void> toggleAdminMode() async {
    _isAdminMode = !_isAdminMode;
    await SharedPrefs.instance.setAdminMode(_isAdminMode);
    notifyListeners();
  }

  Future<void> getAllStations() async {
    setAleartLoading(true);
    List<String> stations = await FirebaseService.instance.getUsersStations();
    log("$stations", name: "Before sort");
    stations.sort(Utils().stationSortCallback);
    log("$stations", name: "After sort");
    _selectedUnits = stations;
    setAleartLoading(false);
    notifyListeners();
  }

  addSelectedUnit(String unit, VoidCallback onExist) async {
    if (_selectedUnits.contains(unit)) {
      onExist();
      return;
    }
    _selectedUnits.add(unit);
    _selectedUnits.sort(Utils().stationSortCallback);
    await FirebaseService.instance.addStation(unit);
    notifyListeners();
  }

  removeSelectedUnit(String unit) async {
    if (!_selectedUnits.contains(unit)) return;
    _selectedUnits.remove(unit);
    // SharedPrefs.instance.removeUnitToList(unit);
    await FirebaseService.instance.removeStation(unit);
    notifyListeners();
  }

  changeCurrentLatLng(LatLng newLatLng) {
    if (newLatLng == _currentLatLng) return;
    _currentLatLng = newLatLng;
    notifyListeners();
  }

  changeSelectedCat(String? newCat) {
    if (newCat == null) return;
    _selectedCat = newCat;
    notifyListeners();
  }

  void changeSelectedSymbols(String symbolcode) {
    if (_selectedSymbolCodes.contains(symbolcode)) {
      _selectedSymbolCodes.remove(symbolcode);
    } else {
      _selectedSymbolCodes.add(symbolcode);
    }
    notifyListeners();
  }

  void filterIncidents() {
    _filteredIncidents.clear();
    if (_selectedSymbolCodes.isEmpty) {
      _filteredIncidents.addAll(_incidents);
      notifyListeners();
      return;
    }
    _filteredIncidents.addAll(
      _incidents.where(
        (element) => _selectedSymbolCodes.contains(element.symbolCode),
      ),
    );
    notifyListeners();
  }

  void clearFilters() {
    _selectedSymbolCodes.clear();
    filterIncidents();
  }

  void addMarker(Marker marker) {
    _markers.add(marker);
    // notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    // notifyListeners();
  }

  /// Fetch incidents from API and cache in Firebase
  Future<void> _fetchAndCacheIncidents() async {
    try {
      setLoading(true);
      // Step 1: Fetch from API
      final response = await services.getIncidents();
      if (response == null) {
        throw Exception('API response is null');
      }

      log('[DEBUG] API returned ${(response['features'] as List).length} incidents');

      // Step 2: Parse incidents
      final incidents = await Future.wait(
          (response['features'] as List).asMap().entries.map((entry) async {
        final index = entry.key;
        final e = entry.value;
        try {
          final incident = Incident.fromJson(e['attributes'], e['geometry']);
          await incident.getCordinatesFromGeometry();
          return incident;
        } catch (e, s) {
          debugPrint('Error parsing incident at index $index: $e');
          debugPrint('Attributes:');
          debugPrint('Geometry:');
          debugPrint('Stack trace: $s');
          rethrow;
        }
      }));

      log('[DEBUG] Successfully parsed ${incidents.length} incidents');

      // Step 3: Save to Firebase for caching
      try {
        await FirebaseService.instance.saveIncidentsToFirebase(incidents);
        _lastApiCall = DateTime.now();
        log('Incidents cached in Firebase at ${_lastApiCall?.toIso8601String()}');
      } catch (e, s) {
        debugPrint('Error saving to Firebase: $e');
        debugPrint('Stack trace: $s');
        rethrow;
      }

      // Step 4: Update local incidents from Firebase
      await _refreshFromFirebase();
    } on DioException catch (e) {
      debugPrint('DioException in fetchAndCacheIncidents: ${e.message}');
      // Fallback to Firebase cache on API failure
      await _refreshFromFirebase();
    } catch (e, s) {
      debugPrint('Error in fetchAndCacheIncidents: $e');
      debugPrint('Stack trace: $s');
    } finally {
      setLoading(false);
    }
  }

  /// Refresh incidents from Firebase cache
  Future<void> _refreshFromFirebase() async {
    try {
      final firebaseIncidents =
          await FirebaseService.instance.getIncidentsFromFirebase();
      _incidents = firebaseIncidents;
      filterIncidents();
      notifyListeners();
      log('Refreshed incidents from Firebase cache, count: ${_incidents.length}');
    } catch (e, s) {
      debugPrint('Error refreshing from Firebase: $e');
      debugPrint('Stack trace: $s');
    }
  }

  /// Force refresh incidents from API, bypassing cache
  Future<void> forceRefreshIncidents({
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      log('[DEBUG] Force refresh requested - bypassing cache');
      // Reset last API call to force fresh data
      _lastApiCall = null;
      await _fetchAndCacheIncidents();
      onSuccess?.call();
    } on DioException catch (e) {
      debugPrint('DioException in forceRefreshIncidents: ${e.message}');
      onError?.call(e.message ?? 'Network error');
    } catch (e, s) {
      debugPrint('Error in forceRefreshIncidents: $e');
      debugPrint('Stack trace: $s');
      onError?.call('$e');
    } finally {
      setLoading(false);
    }
  }

  /// API functions ///
  Future<void> getIncidents({
    dynamic data,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Check if recent API call exists and use cache if recent
      if (_lastApiCall != null &&
          DateTime.now().difference(_lastApiCall!).inSeconds <
              _pollingIntervalSeconds) {
        log('Using cached data, last API call: ${_lastApiCall?.toIso8601String()}');
        await _refreshFromFirebase();

        onSuccess?.call();
        return;
      }

      // Fetch and cache if no recent data
      await _fetchAndCacheIncidents();
      onSuccess?.call();
    } on DioException catch (e) {
      debugPrint('DioException in getIncidents: ${e.message}');
      onError?.call(e.message ?? 'Network error');
    } catch (e, s) {
      debugPrint('Error in getIncidents: $e');
      debugPrint('Stack trace: $s');
      onError?.call('$e');
    } finally {
      setLoading(false);
    }
  }

  /// Get all unique units from current active incidents
  Set<String> getAllAvailableUnits() {
    log('[DEBUG] Extracting units from ${_incidents.length} incidents');
    final Set<String> allUnits = {};
    for (var incident in _incidents) {
      allUnits.addAll(incident.unitAlphanumerics);
    }
    log('[DEBUG] Found ${allUnits.length} unique units total');
    return allUnits;
  }

  /// Get units categorized by type
  Map<String, List<String>> getCategorizedUnits() {
    final allUnits = getAllAvailableUnits();
    final Map<String, List<String>> categorized = {
      'Engines (E)': [],
      'Ambulances (AM)': [],
      'Ladders (L)': [],
      'Battalion Chiefs (BC)': [],
      'Squads (SQ)': [],
      'Rescues (R)': [],
      'Hazmat (HM)': [],
      'Other': [],
    };

    for (var unit in allUnits) {
      if (unit.startsWith('E') && RegExp(r'^E\d+$').hasMatch(unit)) {
        categorized['Engines (E)']!.add(unit);
      } else if (unit.startsWith('AM')) {
        categorized['Ambulances (AM)']!.add(unit);
      } else if (unit.startsWith('L')) {
        categorized['Ladders (L)']!.add(unit);
      } else if (unit.startsWith('BC')) {
        categorized['Battalion Chiefs (BC)']!.add(unit);
      } else if (unit.startsWith('SQ')) {
        categorized['Squads (SQ)']!.add(unit);
      } else if (unit.startsWith('R') && RegExp(r'^R\d+$').hasMatch(unit)) {
        categorized['Rescues (R)']!.add(unit);
      } else if (unit.startsWith('HM')) {
        categorized['Hazmat (HM)']!.add(unit);
      } else {
        categorized['Other']!.add(unit);
      }
    }

    // Remove empty categories and sort units within each category
    categorized.removeWhere((key, value) => value.isEmpty);
    categorized.forEach((key, value) => value.sort());

    log('[DEBUG] Unit breakdown by category:');
    categorized.forEach((key, value) {
      log('[DEBUG]   $key: ${value.length} units');
    });

    return categorized;
  }

  /// Wildcard Helper Methods ///

  /// Check if a unit string is a wildcard pattern
  bool isWildcard(String unit) {
    return unit.endsWith('*');
  }

  /// Get friendly display name for wildcard
  /// BC* → "All Battalion Chiefs"
  /// E1* → "All E1 Units"
  String getWildcardDisplayName(String wildcard) {
    if (!isWildcard(wildcard)) return wildcard;

    final prefix = wildcard.substring(0, wildcard.length - 1);

    // Map known prefixes to friendly names
    const categoryNames = {
      'E': 'All Engines',
      'BC': 'All Battalion Chiefs',
      'AM': 'All Ambulances',
      'L': 'All Ladders',
      'SQ': 'All Squads',
      'R': 'All Rescues',
      'HM': 'All Hazmat Units',
    };

    return categoryNames[prefix] ?? 'All $prefix Units';
  }

  /// Get estimated count of units matching wildcard (for display purposes)
  int? getWildcardMatchCount(String wildcard) {
    if (!isWildcard(wildcard)) return null;

    final prefix = wildcard.substring(0, wildcard.length - 1);
    final allUnits = getAllAvailableUnits();

    return allUnits.where((unit) => unit.startsWith(prefix)).length;
  }

  /// Check if an incident matches any of the user's selected units (with wildcard support)
  /// This mirrors the backend's matchesUserStation() logic for notification filtering
  bool incidentMatchesSelectedUnits(Incident incident) {
    if (_selectedUnits.isEmpty) return false;

    // Get all units from the incident
    final incidentUnits = incident.unitAlphanumerics;
    if (incidentUnits.isEmpty) return false;

    // Check if any incident unit matches any selected unit/wildcard
    for (final selectedUnit in _selectedUnits) {
      if (isWildcard(selectedUnit)) {
        // Wildcard matching: check if any incident unit starts with the wildcard prefix
        final prefix = selectedUnit.substring(0, selectedUnit.length - 1);
        for (final incidentUnit in incidentUnits) {
          if (incidentUnit.startsWith(prefix)) {
            return true;
          }
        }
      } else {
        // Exact match: check if selected unit is in incident units
        if (incidentUnits.contains(selectedUnit)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
