import 'dart:async';
import 'dart:developer';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  //static const String _apiKey = 'test_JenlURuntBXXEUVDUepyAwfLVWL'; // Replace with your actual API key

  static const String _apiKey = 'appl_qFucYHrguHLvLPLgvOFNAlJlreO';

  // Product IDs - must match App Store Connect exactly
  static const String monthlyProductId = 'ca_purchase_monthly';
  static const String yearlyProductId = 'ca_purchase_yearly';

  // Test mode flag - automatically detects test API key or debug mode
  bool get isTestMode => _apiKey.startsWith('test_');

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
      log('[RevenueCat] 🎯 Test Mode: $isTestMode');

      await Purchases.setLogLevel(LogLevel.debug);
      log('[RevenueCat] ✅ Log level set to DEBUG');

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      log('[RevenueCat] ✅ SDK configured');

      // Log app identifier to verify it matches RevenueCat dashboard
      final appUserID = await Purchases.appUserID;
      log('[RevenueCat] 📱 App User ID: $appUserID');

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
      log('[RevenueCat] 🔍 Looking for product IDs:');
      log('[RevenueCat]    - Monthly: $monthlyProductId');
      log('[RevenueCat]    - Yearly: $yearlyProductId');

      _currentOfferings = await Purchases.getOfferings();

      if (_currentOfferings == null) {
        log('[RevenueCat] ⚠️ Offerings is NULL');
        log('[RevenueCat] 💡 This means RevenueCat returned no offerings');
        log('[RevenueCat] 💡 Check: 1) RevenueCat dashboard has offerings configured');
        log('[RevenueCat] 💡 Check: 2) Products are attached to the offering');
        log('[RevenueCat] 💡 Check: 3) Product IDs match App Store Connect exactly');
        return null;
      }

      log('[RevenueCat] ✅ Offerings fetched successfully');
      log('[RevenueCat] 📊 Total offerings: ${_currentOfferings!.all.length}');

      // Log all offerings
      if (_currentOfferings!.all.isNotEmpty) {
        log('[RevenueCat] 📋 All offerings:');
        _currentOfferings!.all.forEach((key, offering) {
          log('[RevenueCat]    - $key: ${offering.identifier} (${offering.availablePackages.length} packages)');
        });
      }

      log('[RevenueCat] 📊 Current offering ID: ${_currentOfferings!.current?.identifier}');

      if (_currentOfferings!.current != null) {
        final current = _currentOfferings!.current!;
        log('[RevenueCat] 📦 Current offering has ${current.availablePackages.length} packages');

        if (current.availablePackages.isEmpty) {
          log('[RevenueCat] ⚠️ WARNING: Current offering has ZERO packages!');
          log('[RevenueCat] 💡 This means:');
          log('[RevenueCat] 💡   1. Products might not be attached to the offering in RevenueCat dashboard');
          log('[RevenueCat] 💡   2. Products might not exist in App Store Connect');
          log('[RevenueCat] 💡   3. Products might have "Missing Metadata" status');
          log('[RevenueCat] 💡   4. Product IDs might not match');
        }

        for (var i = 0; i < current.availablePackages.length; i++) {
          final package = current.availablePackages[i];
          final product = package.storeProduct;
          log('[RevenueCat] 📦 Package $i:');
          log('[RevenueCat]    - Package ID: ${package.identifier}');
          log('[RevenueCat]    - Product ID: ${product.identifier}');
          log('[RevenueCat]    - Title: ${product.title}');
          log('[RevenueCat]    - Price: ${product.priceString}');
          log('[RevenueCat]    - Description: ${product.description}');
          log('[RevenueCat]    - Package Type: ${package.packageType}');
        }

        // Log monthly package
        log('[RevenueCat] 🔍 Looking for MONTHLY package...');
        log('[RevenueCat]    - Expected package identifier: \$rc_monthly');
        log('[RevenueCat]    - Expected product ID: $monthlyProductId');
        final monthlyExists = current.availablePackages.any((p) =>
          p.identifier == '\$rc_monthly' || p.storeProduct.identifier == monthlyProductId
        );
        log('[RevenueCat]    - Monthly package exists: $monthlyExists');

        // Log yearly package
        log('[RevenueCat] 🔍 Looking for YEARLY package...');
        log('[RevenueCat]    - Expected package identifier: \$rc_annual');
        log('[RevenueCat]    - Expected product ID: $yearlyProductId');
        final yearlyExists = current.availablePackages.any((p) =>
          p.identifier == '\$rc_annual' || p.storeProduct.identifier == yearlyProductId
        );
        log('[RevenueCat]    - Yearly package exists: $yearlyExists');
      } else {
        log('[RevenueCat] ⚠️ NO CURRENT OFFERING FOUND!');
        log('[RevenueCat] 💡 Make sure you have configured an offering in RevenueCat dashboard');
        log('[RevenueCat] 💡 And set it as the "current" offering');
        log('[RevenueCat] 💡 And attached products ($monthlyProductId, $yearlyProductId) to it');
      }

      return _currentOfferings;
    } catch (e, stackTrace) {
      log('[RevenueCat] ❌ ERROR FETCHING OFFERINGS: $e');
      log('[RevenueCat] ❌ Error type: ${e.runtimeType}');

      // Check if it's a PurchasesErrorCode
      if (e is PurchasesErrorCode) {
        log('[RevenueCat] ❌ PurchasesErrorCode: $e');
        log('[RevenueCat] 💡 Common causes:');
        log('[RevenueCat] 💡   - Products not found in App Store Connect');
        log('[RevenueCat] 💡   - Products have "Missing Metadata" status');
        log('[RevenueCat] 💡   - Product IDs don\'t match exactly (check for typos)');
        log('[RevenueCat] 💡   - Products not yet approved by Apple');
        log('[RevenueCat] 💡   - StoreKit Configuration file not set up (for testing)');
      }

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
      log('[RevenueCat] 🛒 Attempting to purchase: ${package.identifier}');
      if (isTestMode) {
        log('[RevenueCat] 🧪 TEST MODE ENABLED - StoreKit Configuration testing');
      }

      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      log('[RevenueCat] ✅ Purchase successful: ${customerInfo.entitlements.all}');
      return customerInfo;
    } on PurchasesErrorCode catch (e) {
      log('[RevenueCat] ⚠️ Purchase error code: $e');

      // User cancelled - always return null
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        log('[RevenueCat] ❌ User cancelled purchase');
        return null;
      }

      // In test mode, bypass receipt errors and fetch customer info
      if (isTestMode) {
        log('[RevenueCat] 🧪 TEST MODE: Bypassing receipt error, fetching customer info...');
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          log('[RevenueCat] ✅ TEST MODE: Retrieved customer info successfully');
          log('[RevenueCat] Entitlements: ${customerInfo.entitlements.all}');
          return customerInfo;
        } catch (fetchError) {
          log('[RevenueCat] ❌ Failed to fetch customer info: $fetchError');
          return null;
        }
      }

      // Production mode - return null on error
      log('[RevenueCat] ❌ Purchase error in production mode');
      return null;
    } catch (e, stackTrace) {
      log('[RevenueCat] ❌ UNEXPECTED PURCHASE ERROR: $e');
      log('[RevenueCat] ❌ Error type: ${e.runtimeType}');
      log('[RevenueCat] Stack trace: $stackTrace');

      // In test mode, try to fetch customer info even on unexpected errors
      if (isTestMode) {
        log('[RevenueCat] 🧪 TEST MODE: Attempting to fetch customer info after error...');
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          log('[RevenueCat] ✅ TEST MODE: Retrieved customer info after error');
          return customerInfo;
        } catch (fetchError) {
          log('[RevenueCat] ❌ Failed to fetch customer info: $fetchError');
        }
      }

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
