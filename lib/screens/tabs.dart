import 'package:az_incident_alert/providers/app_provider.dart';
import 'package:az_incident_alert/providers/incidents_provider.dart';
import 'package:az_incident_alert/screens/incidents_screen.dart';
import 'package:az_incident_alert/screens/map_screen.dart';
import 'package:az_incident_alert/utils/app_constants.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabScreen extends StatefulWidget {
  const TabScreen({
    super.key,
    // required this.navigationShell,
  });

  // final StatefulNavigationShell navigationShell;

  @override
  State<StatefulWidget> createState() {
    return _TabScreenState();
  }
}

class _TabScreenState extends State<TabScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('[TabScreen] initState called');
    WidgetsBinding.instance.addObserver(this);
    // Initialize map type on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[TabScreen] Post frame callback - initializing map type');
      context.read<IncidentsProvider>().initializeMapType(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Only update if user hasn't manually selected a map type
    if (!SharedPrefs.instance.hasUserSelectedMapType) {
      context.read<IncidentsProvider>().initializeMapType(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Consumer<AppProvider>(builder: (context, provider, _) {
      return Theme.of(context).platform == TargetPlatform.iOS
          ? Scaffold(
              body: [
                const IncidencesScreen(),
                MapScreen(latLng: context.read<IncidentsProvider>().currentLatLng),
              ][provider.currentIndex],
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.black
                      : CupertinoColors.white,
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                          context: context,
                          icon: CupertinoIcons.house,
                          activeIcon: CupertinoIcons.house_fill,
                          label: 'Home',
                          index: 0,
                          currentIndex: provider.currentIndex,
                        ),
                        _buildTabItem(
                          context: context,
                          icon: CupertinoIcons.map,
                          activeIcon: CupertinoIcons.map_fill,
                          label: 'Map',
                          index: 1,
                          currentIndex: provider.currentIndex,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Scaffold(
              body: SafeArea(
                bottom: false,
                child: [
                  const IncidencesScreen(),
                  MapScreen(latLng: context.read<IncidentsProvider>().currentLatLng),
                ][provider.currentIndex],
              ),
              bottomNavigationBar: NavigationBar(
                height: 60,
                selectedIndex: provider.currentIndex,
                onDestinationSelected: _onTabChange,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(CupertinoIcons.house, size: 24),
                    selectedIcon: Icon(CupertinoIcons.house_fill, size: 24),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(CupertinoIcons.map, size: 24),
                    selectedIcon: Icon(CupertinoIcons.map_fill, size: 24),
                    label: 'Map',
                  ),
                ],
              ),
            );
    });
  }

  Widget _buildTabItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isActive = index == currentIndex;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final color = isActive
        ? (isDark ? CupertinoColors.white : CupertinoTheme.of(context).primaryColor)
        : CupertinoColors.inactiveGray.resolveFrom(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChange(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onTabChange(int index) {
    if (index == 1) {
      context.read<IncidentsProvider>().changeCurrentLatLng(kPhoenixLatLng);
    }

    context.read<AppProvider>().changeIndex(index);
  }
}
