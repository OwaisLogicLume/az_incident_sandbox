import 'dart:convert';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_app_badger/flutter_app_badger.dart';
// import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotificationPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Channel',
    description: 'This channel will use for showing the incident alerts.',
    importance: Importance.high,
    playSound: true,
  );

  // static late bool _isBadgeAvailable;

  static init() async {
    final notificationPermissions = await _messaging.requestPermission(
      provisional: true,
      alert: true,
      badge: true,
    );
    debugPrint(
        'notificationPermissions.alert => ${notificationPermissions.alert}');
    debugPrint(
        'notificationPermissions.authorizationStatus => ${notificationPermissions.authorizationStatus}');
    debugPrint(
        'notificationPermissions.badge => ${notificationPermissions.badge}');
    debugPrint(
        'notificationPermissions.lockScreen => ${notificationPermissions.lockScreen}');
    debugPrint(
        'notificationPermissions.notificationCenter => ${notificationPermissions.notificationCenter}');
    final String? fcm = await _messaging.getToken();
    debugPrint('fcm: $fcm');
    SharedPrefs.instance.setFCM(fcm ?? '');
    // _isBadgeAvailable = await FlutterAppBadger.isAppBadgeSupported();
    // debugPrint('isBadgeAvailable => $_isBadgeAvailable');
    await _initLocalNotifications();
    await _initPushNotifications();
  }

  static Future<void> _initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(iOS: iOS, android: android);

    await _localNotificationPlugin.initialize(settings,
        onDidReceiveNotificationResponse: (payload) {
      final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));
      _handleMessage(message);
    });

    final platform =
        _localNotificationPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _initPushNotifications() async {
    _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final currentSettings = await _messaging.getNotificationSettings();

    debugPrint('currentSettings.alert => ${currentSettings.alert}');
    debugPrint(
        'currentSettings.authorizationStatus => ${currentSettings.authorizationStatus}');
    debugPrint('currentSettings.badge => ${currentSettings.badge}');
    debugPrint('currentSettings.lockScreen => ${currentSettings.lockScreen}');
    debugPrint(
        'currentSettings.notificationCenter => ${currentSettings.notificationCenter}');

    _messaging.getInitialMessage().then(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      debugPrint("message => ${message.toMap()}");

      _localNotificationPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        _notificationDetails(),
        payload: jsonEncode(message.toMap()),
      );

      // await _updateBadgeNumber();
      // FlutterAppBadger.updateBadgeCount(
      //   notifications?.length ?? 0,
      // );
    });
  }

  static Future<void> _handleMessage(RemoteMessage? message) async {
    if (message?.data['incident']?['id'] != null) {}
    debugPrint('message.hashcode => ${message.hashCode}');
    debugPrint('message.messgaeId => ${message?.messageId}');

    // _localNotificationPlugin.cancelAll();
    // await _updateBadgeNumber();

    // showNotification(
    //   id: message.hashCode,
    //   title: message?.notification?.title,
    //   body: message?.notification?.body,
    //   payLoad: json.encode(message?.data),
    // );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('From: ${message.from}');
    debugPrint('Data: ${message.data}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    // showNotification(
    //   id: message.hashCode,
    //   title: message.notification?.title,
    //   body: message.notification?.body,
    //   payLoad: json.encode(message.data),
    // );

    // await _updateBadgeNumber();
    // FlutterAppBadger.updateBadgeCount(
    //   notifications?.length ?? 0,
    // );
  }

  static Future<void> showNotification(
      {int? id, String? title, String? body, String? payLoad}) async {
    return _localNotificationPlugin
        .show(id ?? 0, title, body, _notificationDetails(), payload: payLoad);
  }

  static _notificationDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentBanner: true,
          presentSound: true,
        ),
      );

  // Added for badge count
  /* static _updateBadgeNumber() async {
    try {
      final andPlatform =
          _localNotificationPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final iosPlatform =
          _localNotificationPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final andNotifications = await andPlatform?.getActiveNotifications();
      final iosNotifications = await iosPlatform?.getActiveNotifications();
      debugPrint('notification center => $andNotifications');
      debugPrint('notification center length => ${andNotifications?.length}');

      debugPrint('notification center ios => $iosNotifications');
      debugPrint(
          'notification center length ios => ${iosNotifications?.length}');

      // if (_isBadgeAvailable) {
      await _changeNotificationCount(
        (Platform.isIOS
                ? iosNotifications?.length
                : andNotifications?.length) ??
            0,
      );
      // }
    } catch (e) {
      debugPrint('error whileupdating badge => $e');
    }
  } 

  static _changeNotificationCount(int num) async {
    await FlutterDynamicIcon.setApplicationIconBadgeNumber(num);
  } */
}
