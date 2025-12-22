import 'package:az_incident_alert/utils/app_assets.dart';
import 'package:latlong2/latlong.dart';

/// Map Tiler Key
const String kMapTilerKey = 'vL19ajsuZbJdHPIHS4J3';

/// API Endpoints
const String kPhoenixFireApiPath = '/phxfire/rest/services/Active_Incidents__Public/MapServer/0/query?f=json&cacheHint=true&resultOffset=0&resultRecordCount=100&where=1%3D1&orderByFields=Incident%20DESC&outFields=*&returnGeometry=true&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPoint';

/// Work manager keys
const String kGetIncidentBGTaskIdentifier = 'get_incident_bg_task_identifier';
const String kGetIncidentBGTaskName = 'get_incident_bg_task_name';
const String kGetIncidentBGTaskTag = 'get_incident_bg_task_tag';

/// shared prefs keys
const String kPreferedUnitsKey = 'unit_number';
const String kThemeKey = 'theme';
const String kFCMKey = 'fcm';

/// firebase keys
const String kDeviceIdKey = 'device_id';
const String kStationsKey = 'stations';
const String kAlertedIncidentsKey = 'alerted_incidents';

/// notification keys
const String kChannelId = 'prefered_alerts';
const String kChannelName = 'Prefered Alerts';

/// Map keys
const String kGoogleMapKey = 'AIzaSyARGfWwXIIJwhHfMrxJntOuBBjWxieN5Ng';
const String kESRIMapKey =
    'AAPK94b121cd121e482987e1e32f572916b0xFYrhktob7YZhdKz1gdNhpXjjPG2bly_xL_WgEcqBkTpvYl1Zad1_446UWYaweTX';
const LatLng kPhoenixLatLng = LatLng(33.448376, -112.074036);
const String KDayMapType = 'Day';
const String KNightMapType = 'Night';
const String kSatelliteMapType = 'Map';

const String kNormalMapImage = 'assets/images/normal.png';
const String kNightMapImage = 'assets/images/darkmap.png';
const String kSatelliteMapImage = 'assets/images/satellite.png';



// DEPRECATED: Old PNG icon mapping - replaced by getIconForSymbolCode()
// Kept for reference only - not used in code anymore
final Map<String, String> kSymbolCodesImagesOld = {
  'sc021-airplane': AppAssets.airplane,
  'sc001-alarm': AppAssets.alarm,
  'sc002-bee': AppAssets.bee,
  'sc030-bite': AppAssets.bite,
  'sc003-blueStar': AppAssets.blueStar,
  'sc031-boatFire': AppAssets.boatFire,
  'sc024-commsIssue': AppAssets.commsIssue,
  'sc004-crash': AppAssets.crash,
  'sc017-crashBlue': AppAssets.crashBlue,
  'sc018-crashGray': AppAssets.crashGrey,
  'sc016-crashRed': AppAssets.crashRed,
  'sc005-event': AppAssets.event,
  'sc006-fire': AppAssets.fire,
  'sc033-fire2': AppAssets.fire2,
  'sc007-hazmat': AppAssets.hazmat,
  'sc034-hazmat2': AppAssets.hazmat2,
  'sc008-heart': AppAssets.heart,
  'sc028-heat': AppAssets.heat,
  'sc023-landingZone': AppAssets.landingZone,
  'sc022-lockout': AppAssets.lockOut,
  'sc012-maltese': AppAssets.maltese,
  'sc009-medicalCircle': AppAssets.medicalCircle,
  'sc013-medicalShield': AppAssets.medicalShield,
  'sc035-medicalShield2': AppAssets.medicalShield2,
  'sc027-mountainRescue': AppAssets.mountainRescue,
  'sc010-mrYuk': AppAssets.mrYuk,
  'sc026-openHydrant': AppAssets.openHydrant,
  'sc011-other': AppAssets.other,
  'sc029-powerlines': AppAssets.powerlines,
  'sc014-snake': AppAssets.snake,
  'sc020-telehealth': AppAssets.teleHealth,
  'sc032-trainFire': AppAssets.trainFire,
  'sc025-waterRescue': AppAssets.waterRescue,
  'sc015-zap': AppAssets.zap,
  'sc036-zap2': AppAssets.zap2,
};

/// Intelligent icon resolver with pattern matching
/// Returns appropriate SVG icon path based on symbol code keywords
/// This replaces the old static PNG icon mapping system
String getIconForSymbolCode(String symbolCode) {
  final code = symbolCode.toLowerCase();
  // Apartment/Working fires (sc033-fire2) - check first for priority
  if (code.contains('sc033') || code.contains('fire2')) {
    return 'assets/images/png/fire2.png';
  }

  // Regular fire incidents (sc006-fire)
  if (code.contains('fire') ||
      code.contains('burn') ||
      code.contains('smoke') ||
      code.contains('alarm') ||
      code.contains('flame')) {
    return 'assets/images/png/fire.png';
  }

  // Crash/Accident incidents
  if (code.contains('crash') ||
      code.contains('accident') ||
      code.contains('collision') ||
      code.contains('vehicle')) {
    return 'assets/images/png/car_crash.png';
  }

  // Hazmat incidents
  if (code.contains('chemical') ||
      code.contains('mryuk') ||
      code.contains('toxic') ||
      code.contains('hazmat') ||
      code.contains('spill')) {
    return 'assets/images/png/hazmat.png';
  }

  // medical incidents
  if (code.contains('medical')) {
    return 'assets/images/png/major_medical.png';
  }

  // Electrical hazards
  if (code.contains('zap') ||
      code.contains('electric') ||
      code.contains('powerline') ||
      code.contains('power') ||
      code.contains('wire')) {
    return 'assets/images/png/electric_hazard.png';
  }

  // Water rescue incidents
  if (code.contains('water') ||
      code.contains('boat') ||
      code.contains('lifebuoy') ||
      code.contains('drown') ||
      code.contains('swim') ||
      code.contains('river') ||
      code.contains('lake')) {
    return 'assets/images/png/life_buoy.png';
  }

  // Mountain/cliff rescue
  if (code.contains('mountain') ||
      code.contains('cliff') ||
      code.contains('climb') ||
      code.contains('hike') ||
      code.contains('trail')) {
    return 'assets/images/png/mountain_rescue.png';
  }

  // Snake incidents
  if (code.contains('snake') ||
      code.contains('reptile') ||
      code.contains('serpent') ||
      code.contains('bite')) {
    return 'assets/images/png/snake.png';
  }

  // Bee/insect incidents
  if (code.contains('bee') ||
      code.contains('wasp') ||
      code.contains('hornet') ||
      code.contains('sting') ||
      code.contains('insect') ||
      code.contains('swarm')) {
    return 'assets/images/png/bee.png';
  }

  // Lockout incidents
  if (code.contains('lock') ||
      code.contains('trapped') ||
      code.contains('stuck') ||
      code.contains('key')) {
    return 'assets/images/png/lock_out.png';
  }

  // Default fallback for everything else
  return 'assets/images/png/otherhazard.png';
}

/// Keep old kSymbolCodesImages name for backward compatibility
/// but point to new function logic
final Map<String, String> kSymbolCodesImages = {
  // This map is deprecated - use getIconForSymbolCode() instead
};
