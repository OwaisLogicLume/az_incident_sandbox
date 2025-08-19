import 'package:az_incident_alert/screens/alert_screen.dart';
import 'package:az_incident_alert/screens/incidents_screen.dart';
import 'package:az_incident_alert/screens/map_screen.dart';
import 'package:az_incident_alert/screens/splash.dart';
import 'package:az_incident_alert/screens/subscription_screen.dart';
import 'package:az_incident_alert/screens/tabs.dart';
import 'package:az_incident_alert/widgets/internet_connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class AppNavigator {
  AppNavigator._();

  static final _rootNavigator = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get rootNavigator => _rootNavigator;

  static final _shellNavigatorIncidences =
      GlobalKey<NavigatorState>(debugLabel: "INCIDENCES_NAVIGATOR");

  static final _shellNavigatorAlerts =
      GlobalKey<NavigatorState>(debugLabel: "ALERTS_NAVIGATOR");

  static StatefulNavigationShell? indexedStackNavigationShell;

  static final router = GoRouter(
    initialLocation: AppRoute.subscriptionScreen.path,
    debugLogDiagnostics: true,
    navigatorKey: rootNavigator,
    routes: [
      GoRoute(
        path: AppRoute.subscriptionScreen.path,
        name: AppRoute.subscriptionScreen.name,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoute.splashScreen.path,
        name: AppRoute.splashScreen.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.tabs.path,
        name: AppRoute.tabs.name,
        builder: (context, state) => const TabScreen(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (BuildContext context, GoRouterState state) =>
            const InternetConnectivityWrapper(
          child: IncidencesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.alertScreen.path,
        name: AppRoute.alertScreen.name,
        builder: (BuildContext context, GoRouterState state) =>
            const InternetConnectivityWrapper(
          child: AlertScreen(),
        ),
      ),
      GoRoute(
        path: AppRoute.mapScreen.path,
        name: AppRoute.mapScreen.name,
        builder: (context, state) => InternetConnectivityWrapper(
          child: MapScreen(
            latLng: state.extra as LatLng?,
          ),
        ),
      ),
      /*StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          indexedStackNavigationShell = navigationShell;
          return InternetConnectivityWrapper(
            child: TabScreen(
              navigationShell: navigationShell,
            ),
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellNavigatorIncidences,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const InternetConnectivityWrapper(
                        child: IncidencesScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: AppRoute.mapScreen.name,
                    name: AppRoute.mapScreen.name,
                    builder: (context, state) => InternetConnectivityWrapper(
                      child: MapScreen(
                        latLng: state.extra as LatLng,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAlerts,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.alerts.path,
                name: AppRoute.alerts.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const InternetConnectivityWrapper(child: AlertsScreen()),
                routes: const <RouteBase>[],
              ),
            ],
          ),
        ],
      ),*/
    ],
  );
}

extension PathName on AppRoute {
  String get path => switch (this) { AppRoute.home => "/", _ => "/$name" };
}

enum AppRoute {
  subscriptionScreen,
  splashScreen,
  tabs,
  home,
  alertScreen,
  mapScreen,
  alerts,
}
