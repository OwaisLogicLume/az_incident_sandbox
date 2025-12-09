import 'dart:developer';
import 'dart:io';

import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  SharedPrefs._();

  static final SharedPrefs _instance = SharedPrefs._();

  static SharedPrefs get instance => _instance;

  late final SharedPreferences _prefs;

  final String _purchasePlan = "name";
  final String _trialStartDateKey = 'trialStartDate';
  final String _isTrialActiveKey = 'isTrialActive';
  final String _isSubscribedKey = 'isSubscribed';
  final String _isAdminModeKey = 'isAdminMode';
  final String _mapTypeKey = 'mapType';
  final String _hasUserSelectedMapTypeKey = 'hasUserSelectedMapType';

  init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Theme ///
  String? get theme => _prefs.getString(kThemeKey);

  setTheme(String theme) => _prefs.setString(kThemeKey, theme);

  Future resetTheme() => _prefs.remove(kThemeKey);

  /// FCM token ///
  String? get fcm => _prefs.getString(kFCMKey);

  setFCM(String fcm) => _prefs.setString(kFCMKey, fcm);

  removeFCM() => _prefs.remove(kFCMKey);
  SharedPreferences get prefs => _prefs;

  /// Device Id
  String? get deviceId => _prefs.getString(kDeviceIdKey);

  setDeviceId(String macAddress) => _prefs.setString(kDeviceIdKey, macAddress);

  /// Purchase Plan
  Future<bool> setpurchasePlan(String purchasePlan) =>
      _prefs.setString(_purchasePlan, purchasePlan);

  /// Units
  List<int> get unitNumbers =>
      _prefs
          .getStringList(kPreferedUnitsKey)
          ?.map((e) => int.parse(e))
          .toList() ??
      [];

  void addUnitToList(int unit) {
    final list = unitNumbers;
    list.add(unit);
    list.sort();
    _prefs.setStringList(
        kPreferedUnitsKey, list.map((e) => e.toString()).toList());
    log('new list after adding: ${_prefs.getStringList(kPreferedUnitsKey)}');
  }

  void removeUnitToList(int unit) {
    final list = unitNumbers;
    list.remove(unit);
    _prefs.setStringList(
        kPreferedUnitsKey, list.map((e) => e.toString()).toList());
    log('new list after removing: ${_prefs.getStringList(kPreferedUnitsKey)}');
  }

  /// Free Trial Methods
  Future<void> startFreeTrial() async {
    await _prefs.setBool(_isTrialActiveKey, true);
    await _prefs.setString(
        _trialStartDateKey, DateTime.now().toIso8601String());
  }

  Future<bool> isTrialStillValid() async {
    final isActive = _prefs.getBool(_isTrialActiveKey) ?? false;
    final startDateStr = _prefs.getString(_trialStartDateKey);
    if (!isActive || startDateStr == null) return false;

    final startDate = DateTime.parse(startDateStr);
    // FIXED: Changed from 1 minute to 3 days as per requirements
    return DateTime.now().isBefore(startDate.add(const Duration(days: 3)));
  }

  /// Subscription Status
  Future<void> setSubscribed(bool value) async {
    await _prefs.setBool(_isSubscribedKey, value);
  }

  Future<bool> get isSubscribed async {
    return _prefs.getBool(_isSubscribedKey) ?? false;
  }

  Future<void> setTrialActive(bool value) async {
    await _prefs.setBool(_isTrialActiveKey, value);
  }

  Future<void> setTrialStartDate(DateTime date) async {
    await _prefs.setString(_trialStartDateKey, date.toIso8601String());
  }

  /// Get or generate consistent user ID for RevenueCat
  Future<String> getOrGenerateUserId() async {
    // First check if we already have a stored device ID
    String? storedDeviceId = deviceId;

    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      log('[SharedPrefs] Using stored device ID: $storedDeviceId');
      return storedDeviceId;
    }

    // Generate new device ID
    try {
      final deviceInfo = DeviceInfoPlugin();
      String uniqueId;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        uniqueId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
        log('[SharedPrefs] Generated iOS device ID: $uniqueId');
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        uniqueId = androidInfo.id;
        log('[SharedPrefs] Generated Android device ID: $uniqueId');
      } else {
        uniqueId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        log('[SharedPrefs] Generated fallback device ID: $uniqueId');
      }

      // Store the device ID for future use
      await setDeviceId(uniqueId);
      return uniqueId;
    } catch (e) {
      log('[SharedPrefs] Error generating device ID: $e');
      // Fallback to timestamp-based ID
      final fallbackId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await setDeviceId(fallbackId);
      return fallbackId;
    }
  }

  /// Admin Mode
  bool get isAdminMode => _prefs.getBool(_isAdminModeKey) ?? false;

  Future<void> setAdminMode(bool value) async {
    await _prefs.setBool(_isAdminModeKey, value);
    log('Admin mode ${value ? 'enabled' : 'disabled'}');
  }

  /// Map Type Persistence
  String? get savedMapType => _prefs.getString(_mapTypeKey);

  Future<void> saveMapType(String mapType) async {
    await _prefs.setString(_mapTypeKey, mapType);
    await _prefs.setBool(_hasUserSelectedMapTypeKey, true);
    log('Map type saved: $mapType');
  }

  bool get hasUserSelectedMapType => _prefs.getBool(_hasUserSelectedMapTypeKey) ?? false;

  /// Clear map type preference to reset to system theme detection
  Future<void> clearMapTypePreference() async {
    await _prefs.remove(_mapTypeKey);
    await _prefs.remove(_hasUserSelectedMapTypeKey);
    log('Map type preference cleared - will follow system theme');
  }
}
