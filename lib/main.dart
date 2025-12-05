import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:az_incident_alert/firebase_options.dart';
import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/providers/subscription_provider.dart';
import 'package:az_incident_alert/services/base_api_service.dart';
import 'package:az_incident_alert/services/firabse_service.dart';
import 'package:az_incident_alert/services/incident_service.dart';
import 'package:az_incident_alert/services/push_notification_service.dart';
import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/app_themes.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeCoreApp();
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  try {
    final file = File('env');
    log('Checking env file exists: ${file.existsSync()}');
    log('File path: ${file.absolute.path}');
    await dotenv.load(fileName: 'env');
    log('Environment variables loaded successfully');

    final mapboxToken = dotenv.env['ACCESS_MAP_TOKEN'];
    if (mapboxToken == null || mapboxToken.isEmpty) {
      throw Exception('ACCESS_MAP_TOKEN is missing in env file');
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

  // Initialize Firebase (handle case where it's already initialized by iOS/Android)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      log('Firebase already initialized, using existing instance');
    } else {
      rethrow;
    }
  }

  //initialize Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService.init();
  await _getDeviceId();
  await FirebaseService.instance.init();

  // Initialize SubscriptionProvider with consistent user ID
  try {
    final userId = await SharedPrefs.instance.getOrGenerateUserId();
    log('[Main] Initializing SubscriptionProvider with user ID: $userId');
    await SubscriptionProvider().initialize(userId);
    log('[Main] ✅ SubscriptionProvider initialized successfully');
  } catch (e, stackTrace) {
    log('[Main] ⚠️ Failed to initialize SubscriptionProvider: $e');
    log('[Main] Stack trace: $stackTrace');
    // Continue app startup even if subscription initialization fails
  }

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  // Example: log startup event
  Future<void> logEvent() async {
    await analytics.logEvent(
      name: 'test_event',
      parameters: {
        'string_param': 'hello',
        'int_param': 42,
      },
    );
  }
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
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IncidentsProvider>(
          create: (_) => IncidentsProvider(IncidentService.instance),
        ),
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
        ),
      ],
      child: buildMyapp(analytics),
    );
  }

  Widget buildMyapp(var analytics) => ScreenUtilInit(
        ensureScreenSize: true,
        designSize: const ui.Size(390, 844),
        builder: (context, child) =>
            Consumer<AppProvider>(builder: (context, provider, _) {
          return MaterialApp.router(
            title: 'Incidence App',
            themeMode: provider.currentThemeMode,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            routerConfig: AppNavigator.router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Navigator(
                observers: [
                  FirebaseAnalyticsObserver(analytics: analytics),
                ],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => child!),
              );
            },
          );
        }),
      );
}