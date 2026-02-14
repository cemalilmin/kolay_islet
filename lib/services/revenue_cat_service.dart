import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat Subscription Service
/// Handles all subscription logic for iOS and Android
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // RevenueCat API Keys
  static const String _appleApiKey = 'test_hLJmIYSNWvezwD0ksUdDp0coJnk';
  // TODO: Google Play API key eklenecek
  static const String _googleApiKey = 'goog_api_key_placeholder';

  // Product IDs
  static const String monthlyProductId = 'kolayislet_monthly';
  static const String yearlyProductId = 'kolayislet_yearly';

  // Entitlement ID
  static const String premiumEntitlement = 'premium';

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else {
        debugPrint('RevenueCat: Unsupported platform');
        return;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[premiumEntitlement]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat isPremium error: $e');
      return false;
    }
  }

  /// Get available subscription packages
  Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        return current.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('RevenueCat getPackages error: $e');
      return [];
    }
  }

  /// Purchase a subscription package
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      // After purchase, check entitlements via customerInfo
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[premiumEntitlement]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[premiumEntitlement]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat restore error: $e');
      return false;
    }
  }

  /// Get customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo error: $e');
      return null;
    }
  }

  /// Listen to customer info updates
  void addCustomerInfoUpdateListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Login user (sync with RevenueCat)
  Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('RevenueCat logged in: $userId');
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint('RevenueCat logged out');
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }
}
