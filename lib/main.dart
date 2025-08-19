import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:az_incident_alert/firebase_options.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/services/push_notification_service.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/services/incident_service.dart';
import 'package:az_incident_alert/utils/app_themes.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:az_incident_alert/firebase_options.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/services/push_notification_service.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/services/incident_service.dart';
import 'package:az_incident_alert/utils/app_themes.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeCoreApp();
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  try {
    final file = File('.env');
    log('Checking .env file exists: ${file.existsSync()}');
    log('File path: ${file.absolute.path}');

    await dotenv.load(fileName: '.env');
    log('Environment variables loaded successfully');

    final mapboxToken = dotenv.env['ACCESS_MAP_TOKEN'];
    if (mapboxToken == null || mapboxToken.isEmpty) {
      throw Exception('ACCESS_MAP_TOKEN is missing in .env file');
    }
    MapboxOptions.setAccessToken(mapboxToken);
  } catch (e, stackTrace) {
    log('Error in setup: $e', stackTrace: stackTrace);
    throw Exception('Failed to load environment variables: $e');
  }
}

Future<void> _initializeCoreApp() async {
  await BaseRepository.instance.initialize();
  await SharedPrefs.instance.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  await _getDeviceId();
  await FirebaseService.instance.init();
}

Future<void> _getDeviceId() async {
  log('shared prefs device id => ${SharedPrefs.instance.deviceId}');
  if (SharedPrefs.instance.deviceId != null) return;
  var deviceInfo = DeviceInfoPlugin();
  String? deviceId;

  if (Platform.isIOS) {
    var iosDeviceInfo = await deviceInfo.iosInfo;
    deviceId = iosDeviceInfo.identifierForVendor;
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    deviceId = androidDeviceInfo.id;
  }
  log('Device Id: $deviceId');

  SharedPrefs.instance.setDeviceId(deviceId ?? "");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IncidentsProvider>(
          create: (_) => IncidentsProvider(IncidentService.instance),
        ),
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
        ),
      ],
      child: buildMyapp(),
    );
  }

  Widget buildMyapp() => ScreenUtilInit(
        ensureScreenSize: true,
        designSize: ui.Size(390, 844),
        builder: (context, child) =>
            Consumer<AppProvider>(builder: (context, provider, _) {
          return MaterialApp.router(
            title: 'Incidence App',
            themeMode: provider.currentThemeMode,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            routerConfig: AppNavigator.router,
            debugShowCheckedModeBanner: false,
          );
        }),
      );
}

// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
// import 'package:az_incident_alert/firebase_options.dart';
// import 'package:az_incident_alert/services/firabse_service.dart';
// import 'package:az_incident_alert/services/push_notification_service.dart';
// import 'package:az_incident_alert/utils/shared_prefs.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:az_incident_alert/providers/incidents_provider.dart';
// import 'package:az_incident_alert/providers/app_provider.dart';
// import 'package:az_incident_alert/services/base_api_service.dart';
// import 'package:az_incident_alert/services/incident_service.dart';
// import 'package:az_incident_alert/utils/app_themes.dart';
// import 'package:az_incident_alert/utils/app_router.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _initializeCoreApp();

//   runApp(const MyApp());
// }

// _initializeCoreApp() async {
//   await BaseRepository.instance.initialize();
//   await SharedPrefs.instance.init();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   await NotificationService.init();
//   await _getDeviceId();
//   await FirebaseService.instance.init();
// }

// Future<void> _getDeviceId() async {
//   log('shared prefs device id => ${SharedPrefs.instance.deviceId}');
//   if (SharedPrefs.instance.deviceId != null) return;
//   var deviceInfo = DeviceInfoPlugin();
//   String? deviceId;

//   if (Platform.isIOS) {
//     var iosDeviceInfo = await deviceInfo.iosInfo;
//     deviceId = iosDeviceInfo.identifierForVendor;
//   } else if (Platform.isAndroid) {
//     var androidDeviceInfo = await deviceInfo.androidInfo;
//     deviceId = androidDeviceInfo.id;
//   }
//   log('Device Id : $deviceId');

//   SharedPrefs.instance.setDeviceId(deviceId ?? "");
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setPreferredOrientations(
//       [
//         DeviceOrientation.portraitDown,
//         DeviceOrientation.portraitUp,
//       ],
//     );

//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider<IncidentsProvider>(
//           create: (_) =>
//               IncidentsProvider(IncidentService.instance)..getAllStations(),
//         ),
//         ChangeNotifierProvider<AppProvider>(
//           create: (_) => AppProvider(),
//         ),
//       ],
//       child: buildMyapp(),
//     );
//   }

//   Widget buildMyapp() => ScreenUtilInit(
//         ensureScreenSize: true,
//         designSize: const Size(390, 844),
//         builder: (context, child) =>
//             Consumer<AppProvider>(builder: (context, provider, _) {
//           return MaterialApp.router(
//             title: 'Incidence App',
//             themeMode: provider.currentThemeMode,
//             theme: AppThemes.lightTheme,
//             darkTheme: AppThemes.darkTheme,
//             routerConfig: AppNavigator.router,
//             debugShowCheckedModeBanner: false,
//           );
//         }),
//       );
// }