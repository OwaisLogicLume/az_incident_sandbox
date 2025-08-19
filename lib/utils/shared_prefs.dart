import 'dart:developer';

import 'package:az_incident_alert/utils/app_constants.dart';
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
    return DateTime.now().isBefore(startDate.add(const Duration(minutes: 1)));
  }

  /// Subscription Status
  Future<void> setSubscribed(bool value) async {
    await _prefs.setBool(_isSubscribedKey, value);
  }

  Future<bool> get isSubscribed async {
    return _prefs.getBool(_isSubscribedKey) ?? false;
  }
}
