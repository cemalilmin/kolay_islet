import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings Service - manages app preferences with persistence
/// Singleton pattern with ChangeNotifier for reactive updates
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // ============== DEFAULT VALUES ==============
  static const int _defaultShippingBufferDays = 3;
  static const int _defaultCleaningDurationDays = 2;
  static const String _defaultShopName = '';
  static const String _defaultShopPhone = '';
  static const String _defaultReceiptDisclaimer = 'Kiralamalar 19:00\'a kadar iade edilmelidir.';
  static const bool _defaultOverdueNotifications = true;

  // ============== KEYS ==============
  static const String _keyShippingBuffer = 'shipping_buffer_days';
  static const String _keyCleaningDuration = 'cleaning_duration_days';
  static const String _keyShopName = 'shop_name';
  static const String _keyShopPhone = 'shop_phone';
  static const String _keyReceiptDisclaimer = 'receipt_disclaimer';
  static const String _keyOverdueNotifications = 'overdue_notifications';

  // ============== INITIALIZATION ==============
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    notifyListeners();
  }

  // ============== GETTERS ==============

  /// Shipping buffer days for city-to-city logistics
  int get shippingBufferDays => 
      _prefs?.getInt(_keyShippingBuffer) ?? _defaultShippingBufferDays;

  /// Default cleaning/maintenance duration
  int get cleaningDurationDays => 
      _prefs?.getInt(_keyCleaningDuration) ?? _defaultCleaningDurationDays;

  /// Shop name for receipts
  String get shopName => 
      _prefs?.getString(_keyShopName) ?? _defaultShopName;

  /// Shop contact phone
  String get shopPhone => 
      _prefs?.getString(_keyShopPhone) ?? _defaultShopPhone;

  /// Disclaimer text for digital receipts
  String get receiptDisclaimer => 
      _prefs?.getString(_keyReceiptDisclaimer) ?? _defaultReceiptDisclaimer;

  /// Enable overdue rental notifications
  bool get overdueNotificationsEnabled => 
      _prefs?.getBool(_keyOverdueNotifications) ?? _defaultOverdueNotifications;

  /// Get cleaning duration as Duration object (for use in logic)
  Duration get cleaningDuration => Duration(days: cleaningDurationDays);

  // ============== SETTERS ==============

  Future<void> setShippingBufferDays(int days) async {
    await _prefs?.setInt(_keyShippingBuffer, days.clamp(0, 14));
    notifyListeners();
  }

  Future<void> setCleaningDurationDays(int days) async {
    await _prefs?.setInt(_keyCleaningDuration, days.clamp(1, 14));
    notifyListeners();
  }

  Future<void> setShopName(String name) async {
    await _prefs?.setString(_keyShopName, name);
    notifyListeners();
  }

  Future<void> setShopPhone(String phone) async {
    await _prefs?.setString(_keyShopPhone, phone);
    notifyListeners();
  }

  Future<void> setReceiptDisclaimer(String text) async {
    await _prefs?.setString(_keyReceiptDisclaimer, text);
    notifyListeners();
  }

  Future<void> setOverdueNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyOverdueNotifications, enabled);
    notifyListeners();
  }

  // ============== UTILITY ==============

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.remove(_keyShippingBuffer);
    await _prefs?.remove(_keyCleaningDuration);
    await _prefs?.remove(_keyShopName);
    await _prefs?.remove(_keyShopPhone);
    await _prefs?.remove(_keyReceiptDisclaimer);
    await _prefs?.remove(_keyOverdueNotifications);
    notifyListeners();
  }

  /// Check if settings are loaded
  bool get isInitialized => _isInitialized;
}
