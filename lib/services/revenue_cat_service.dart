import 'dart:async';
import 'dart:developer';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  static const String _apiKey = 'test_JenlURuntBXXEUVDUepyAwfLVWL'; // Replace with your actual API key

  // Product IDs - must match App Store Connect exactly
  static const String monthlyProductId = 'ca_purchase_monthly';
  static const String yearlyProductId = 'ca_purchase_yearly';

  bool _isInitialized = false;
  Offerings? _currentOfferings;

  /// Initialize RevenueCat SDK
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      log('[RevenueCat] ⚠️ Already initialized');
      return;
    }

    try {
      log('[RevenueCat] 🚀 Starting initialization...');
      log('[RevenueCat] 📝 API Key: ${_apiKey.substring(0, 15)}...');
      log('[RevenueCat] 👤 User ID: $userId');

      await Purchases.setLogLevel(LogLevel.debug);
      log('[RevenueCat] ✅ Log level set to DEBUG');

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      log('[RevenueCat] ✅ SDK configured');

      // Set user ID for RevenueCat
      await Purchases.logIn(userId);
      log('[RevenueCat] ✅ User logged in');

      _isInitialized = true;
      log('[RevenueCat] ✅ Initialization complete');

      // Fetch offerings
      await fetchOfferings();
    } catch (e, stackTrace) {
      log('[RevenueCat] ❌ INITIALIZATION ERROR: $e');
      log('[RevenueCat] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch available offerings from RevenueCat
  Future<Offerings?> fetchOfferings() async {
    try {
      log('[RevenueCat] 📦 Fetching offerings...');
      _currentOfferings = await Purchases.getOfferings();

      if (_currentOfferings == null) {
        log('[RevenueCat] ⚠️ Offerings is NULL');
        return null;
      }

      log('[RevenueCat] ✅ Offerings fetched successfully');
      log('[RevenueCat] 📊 Total offerings: ${_currentOfferings!.all.length}');
      log('[RevenueCat] 📊 Current offering ID: ${_currentOfferings!.current?.identifier}');

      if (_currentOfferings!.current != null) {
        final current = _currentOfferings!.current!;
        log('[RevenueCat] 📦 Current offering has ${current.availablePackages.length} packages');

        for (var i = 0; i < current.availablePackages.length; i++) {
          final package = current.availablePackages[i];
          final product = package.storeProduct;
          log('[RevenueCat] 📦 Package $i:');
          log('[RevenueCat]    - Package ID: ${package.identifier}');
          log('[RevenueCat]    - Product ID: ${product.identifier}');
          log('[RevenueCat]    - Title: ${product.title}');
          log('[RevenueCat]    - Price: ${product.priceString}');
          log('[RevenueCat]    - Description: ${product.description}');
        }

        // Log monthly package
        log('[RevenueCat] 🔍 Looking for MONTHLY package...');
        log('[RevenueCat]    - Expected package identifier: \$rc_monthly');
        log('[RevenueCat]    - Expected product ID: $monthlyProductId');

        // Log yearly package
        log('[RevenueCat] 🔍 Looking for YEARLY package...');
        log('[RevenueCat]    - Expected package identifier: \$rc_annual');
        log('[RevenueCat]    - Expected product ID: $yearlyProductId');
      } else {
        log('[RevenueCat] ⚠️ NO CURRENT OFFERING FOUND!');
        log('[RevenueCat] 💡 Make sure you have configured an offering in RevenueCat dashboard');
        log('[RevenueCat] 💡 And attached products to it');
      }

      return _currentOfferings;
    } catch (e, stackTrace) {
      log('[RevenueCat] ❌ ERROR FETCHING OFFERINGS: $e');
      log('[RevenueCat] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get monthly package
  Package? getMonthlyPackage() {
    log('[RevenueCat] 🔍 Getting monthly package...');
    final offering = _currentOfferings?.current;

    if (offering == null) {
      log('[RevenueCat] ❌ No current offering available');
      return null;
    }

    log('[RevenueCat] Available packages: ${offering.availablePackages.length}');
    for (var pkg in offering.availablePackages) {
      log('[RevenueCat]   - ${pkg.identifier} (${pkg.storeProduct.identifier})');
    }

    try {
      final package = offering.availablePackages.firstWhere(
        (package) => package.identifier == '\$rc_monthly',
        orElse: () => offering.monthly!,
      );
      log('[RevenueCat] ✅ Found monthly package: ${package.identifier}');
      return package;
    } catch (e) {
      log('[RevenueCat] ❌ Monthly package not found: $e');
      return null;
    }
  }

  /// Get yearly package
  Package? getYearlyPackage() {
    log('[RevenueCat] 🔍 Getting yearly package...');
    final offering = _currentOfferings?.current;

    if (offering == null) {
      log('[RevenueCat] ❌ No current offering available');
      return null;
    }

    log('[RevenueCat] Available packages: ${offering.availablePackages.length}');
    for (var pkg in offering.availablePackages) {
      log('[RevenueCat]   - ${pkg.identifier} (${pkg.storeProduct.identifier})');
    }

    try {
      final package = offering.availablePackages.firstWhere(
        (package) => package.identifier == '\$rc_annual',
        orElse: () => offering.annual!,
      );
      log('[RevenueCat] ✅ Found yearly package: ${package.identifier}');
      return package;
    } catch (e) {
      log('[RevenueCat] ❌ Yearly package not found: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      log('Attempting to purchase: ${package.identifier}');
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      log('Purchase successful: ${customerInfo.entitlements.all}');
      return customerInfo;
    } on PurchasesErrorCode catch (e) {
      log('Purchase error: $e');
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        log('User cancelled purchase');
      } else if (e == PurchasesErrorCode.purchaseNotAllowedError) {
        log('Purchase not allowed');
      }
      return null;
    } catch (e) {
      log('Unexpected purchase error: $e');
      return null;
    }
  }

  /// Restore purchases
  Future<CustomerInfo?> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      log('Purchases restored: ${customerInfo.entitlements.all}');
      return customerInfo;
    } catch (e) {
      log('Error restoring purchases: $e');
      return null;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // Check if user has any active entitlements
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      log('Error checking subscription status: $e');
      return false;
    }
  }

  /// Get customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      log('Error getting customer info: $e');
      return null;
    }
  }

  /// Log out user
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      _isInitialized = false;
      log('User logged out from RevenueCat');
    } catch (e) {
      log('Error logging out: $e');
    }
  }

  /// Get all available packages
  List<Package> getAllPackages() {
    final offering = _currentOfferings?.current;
    if (offering == null) return [];
    return offering.availablePackages;
  }

  Offerings? get currentOfferings => _currentOfferings;
}
