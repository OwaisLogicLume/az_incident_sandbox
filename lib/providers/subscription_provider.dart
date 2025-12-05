import 'dart:async';
import 'dart:developer';
import 'package:az_incident_alert/services/revenue_cat_service.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum SubscriptionStatus {
  none,       // No subscription or trial
  trial,      // Active trial period
  active,     // Paid subscription active
  expired,    // Subscription expired
}

class SubscriptionProvider extends ChangeNotifier {
  static final SubscriptionProvider _instance = SubscriptionProvider._internal();
  factory SubscriptionProvider() => _instance;
  SubscriptionProvider._internal();

  final RevenueCatService _revenueCatService = RevenueCatService();

  SubscriptionStatus _status = SubscriptionStatus.none;
  CustomerInfo? _customerInfo;
  DateTime? _expirationDate;
  bool _isInitialized = false;

  SubscriptionStatus get status => _status;
  CustomerInfo? get customerInfo => _customerInfo;
  DateTime? get expirationDate => _expirationDate;
  bool get isInitialized => _isInitialized;

  bool get hasAccess =>
      _status == SubscriptionStatus.trial ||
      _status == SubscriptionStatus.active;

  /// Initialize the subscription provider
  Future<void> initialize(String userId) async {
    if (_isInitialized) {
      log('[SubscriptionProvider] Already initialized');
      return;
    }

    try {
      log('[SubscriptionProvider] 🚀 Initializing...');

      // Initialize RevenueCat
      await _revenueCatService.initialize(userId);

      // Check current subscription status
      await refreshSubscriptionStatus();

      // Listen to CustomerInfo updates
      _setupCustomerInfoListener();

      _isInitialized = true;
      log('[SubscriptionProvider] ✅ Initialization complete');
    } catch (e, stackTrace) {
      log('[SubscriptionProvider] ❌ Initialization error: $e');
      log('[SubscriptionProvider] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Setup listener for CustomerInfo changes
  void _setupCustomerInfoListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      log('[SubscriptionProvider] 📡 CustomerInfo updated');
      _updateSubscriptionStatus(customerInfo);
    });
  }

  /// Refresh subscription status from RevenueCat
  Future<void> refreshSubscriptionStatus() async {
    try {
      log('[SubscriptionProvider] 🔄 Refreshing subscription status...');

      final customerInfo = await _revenueCatService.getCustomerInfo();
      if (customerInfo != null) {
        await _updateSubscriptionStatus(customerInfo);
      } else {
        // Fallback to local trial check
        await _checkLocalTrialStatus();
      }
    } catch (e) {
      log('[SubscriptionProvider] ❌ Error refreshing status: $e');
      // Fallback to local trial check
      await _checkLocalTrialStatus();
    }
  }

  /// Update subscription status based on CustomerInfo
  Future<void> _updateSubscriptionStatus(CustomerInfo customerInfo) async {
    _customerInfo = customerInfo;

    log('[SubscriptionProvider] 📊 Analyzing entitlements...');
    log('[SubscriptionProvider] Active entitlements: ${customerInfo.entitlements.active.length}');

    if (customerInfo.entitlements.active.isNotEmpty) {
      // User has active entitlement
      final entitlement = customerInfo.entitlements.active.values.first;

      // Parse expiration date from String to DateTime if it exists
      if (entitlement.expirationDate != null) {
        try {
          _expirationDate = DateTime.parse(entitlement.expirationDate!);
        } catch (e) {
          log('[SubscriptionProvider] ⚠️ Error parsing expiration date: $e');
          _expirationDate = null;
        }
      }

      log('[SubscriptionProvider] ✅ Active entitlement found');
      log('[SubscriptionProvider] Product ID: ${entitlement.productIdentifier}');
      log('[SubscriptionProvider] Expiration: $_expirationDate');

      // Check if in trial period
      if (entitlement.periodType == PeriodType.trial) {
        _status = SubscriptionStatus.trial;
        log('[SubscriptionProvider] 🎁 Status: TRIAL');

        // Save trial status locally
        await SharedPrefs.instance.setTrialActive(true);
        await SharedPrefs.instance.setTrialStartDate(DateTime.now());
      } else {
        _status = SubscriptionStatus.active;
        log('[SubscriptionProvider] 💎 Status: ACTIVE');

        // Save subscription status
        await SharedPrefs.instance.setSubscribed(true);
      }
    } else if (customerInfo.entitlements.all.isNotEmpty) {
      // User had subscription but it expired
      _status = SubscriptionStatus.expired;
      log('[SubscriptionProvider] ⏰ Status: EXPIRED');

      // Clear local subscription status
      await SharedPrefs.instance.setSubscribed(false);
      await SharedPrefs.instance.setTrialActive(false);
    } else {
      // Check local trial status
      await _checkLocalTrialStatus();
    }

    notifyListeners();
  }

  /// Check local trial status (fallback when RevenueCat is unavailable)
  Future<void> _checkLocalTrialStatus() async {
    final isTrialValid = await SharedPrefs.instance.isTrialStillValid();
    final isSubscribed = await SharedPrefs.instance.isSubscribed;

    if (isSubscribed) {
      _status = SubscriptionStatus.active;
      log('[SubscriptionProvider] 💎 Status: ACTIVE (from local storage)');
    } else if (isTrialValid) {
      _status = SubscriptionStatus.trial;
      log('[SubscriptionProvider] 🎁 Status: TRIAL (from local storage)');
    } else {
      _status = SubscriptionStatus.none;
      log('[SubscriptionProvider] ❌ Status: NONE');
    }

    notifyListeners();
  }

  /// Handle successful purchase
  Future<void> handlePurchaseSuccess(CustomerInfo customerInfo) async {
    log('[SubscriptionProvider] 🎉 handlePurchaseSuccess called');
    log('[SubscriptionProvider] 📊 CustomerInfo - Active entitlements: ${customerInfo.entitlements.active.length}');
    log('[SubscriptionProvider] 📊 CustomerInfo - All entitlements: ${customerInfo.entitlements.all.length}');

    await _updateSubscriptionStatus(customerInfo);

    log('[SubscriptionProvider] ✅ handlePurchaseSuccess completed');
    log('[SubscriptionProvider] 📊 Final status: $_status');
    log('[SubscriptionProvider] 📊 Has access: $hasAccess');
  }

  /// Handle purchase restoration
  Future<bool> restorePurchases() async {
    try {
      log('[SubscriptionProvider] 🔄 Restoring purchases...');

      final customerInfo = await _revenueCatService.restorePurchases();
      if (customerInfo != null) {
        await _updateSubscriptionStatus(customerInfo);

        if (hasAccess) {
          log('[SubscriptionProvider] ✅ Purchases restored successfully');
          return true;
        } else {
          log('[SubscriptionProvider] ⚠️ No active purchases found');
          return false;
        }
      }

      return false;
    } catch (e) {
      log('[SubscriptionProvider] ❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Clear all subscription data (for logout)
  Future<void> clearSubscriptionData() async {
    log('[SubscriptionProvider] 🧹 Clearing subscription data...');

    await _revenueCatService.logOut();
    await SharedPrefs.instance.setSubscribed(false);
    await SharedPrefs.instance.setTrialActive(false);

    _status = SubscriptionStatus.none;
    _customerInfo = null;
    _expirationDate = null;
    _isInitialized = false;

    notifyListeners();
    log('[SubscriptionProvider] ✅ Subscription data cleared');
  }

  /// Get formatted expiration date
  String getFormattedExpirationDate() {
    if (_expirationDate == null) return 'N/A';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[_expirationDate!.month - 1]} ${_expirationDate!.day}, ${_expirationDate!.year}';
  }

  /// Get subscription status text
  String getStatusText() {
    switch (_status) {
      case SubscriptionStatus.none:
        return 'No Active Subscription';
      case SubscriptionStatus.trial:
        return '3-Day Free Trial';
      case SubscriptionStatus.active:
        return 'Premium Subscription';
      case SubscriptionStatus.expired:
        return 'Subscription Expired';
    }
  }
}
