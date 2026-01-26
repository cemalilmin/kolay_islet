import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Callback for when notification is tapped
  static Function(String? bookingId)? onNotificationTap;

  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    print('DEBUG: NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    print('DEBUG: Notification tapped with payload: ${response.payload}');
    if (response.payload != null && onNotificationTap != null) {
      onNotificationTap!(response.payload);
    }
  }

  // Schedule preparation day notification (1 day before rental)
  Future<void> schedulePreparationNotification({
    required String bookingId,
    required String productName,
    required DateTime rentalDate,
  }) async {
    final preparationDate = rentalDate.subtract(const Duration(days: 1));
    final scheduledTime = DateTime(
      preparationDate.year,
      preparationDate.month,
      preparationDate.day,
      10, // 10:00
      0,
    );

    // Don't schedule if date is in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      print('DEBUG: Skipping preparation notification - date is in the past');
      return;
    }

    final notificationId = bookingId.hashCode;

    await _notifications.zonedSchedule(
      notificationId,
      '📦 Hazırlık Günü',
      'Bugün $productName için hazırlık günü',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rental_reminders',
          'Kiralama Hatırlatıcıları',
          channelDescription: 'Yaklaşan kiralamalar için hatırlatmalar',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: bookingId,
    );

    print('DEBUG: Scheduled preparation notification for $productName on $scheduledTime');
  }

  // Schedule rental day notification
  Future<void> scheduleRentalDayNotification({
    required String bookingId,
    required String productName,
    required DateTime rentalDate,
  }) async {
    final scheduledTime = DateTime(
      rentalDate.year,
      rentalDate.month,
      rentalDate.day,
      10, // 10:00
      0,
    );

    // Don't schedule if date is in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      print('DEBUG: Skipping rental day notification - date is in the past');
      return;
    }

    // Use a different ID for rental day notification
    final notificationId = bookingId.hashCode + 1;

    await _notifications.zonedSchedule(
      notificationId,
      '📅 Kiralama Günü',
      '$productName için kiralama günü - Ürün hazır mı?',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rental_reminders',
          'Kiralama Hatırlatıcıları',
          channelDescription: 'Yaklaşan kiralamalar için hatırlatmalar',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: bookingId,
    );

    print('DEBUG: Scheduled rental day notification for $productName on $scheduledTime');
  }

  // Schedule both notifications for a booking
  Future<void> scheduleBookingNotifications({
    required String bookingId,
    required String productName,
    required DateTime rentalDate,
  }) async {
    await schedulePreparationNotification(
      bookingId: bookingId,
      productName: productName,
      rentalDate: rentalDate,
    );
    await scheduleRentalDayNotification(
      bookingId: bookingId,
      productName: productName,
      rentalDate: rentalDate,
    );
  }

  // Cancel notifications for a booking
  Future<void> cancelBookingNotifications(String bookingId) async {
    final notificationId = bookingId.hashCode;
    await _notifications.cancel(notificationId); // Preparation notification
    await _notifications.cancel(notificationId + 1); // Rental day notification
    print('DEBUG: Cancelled notifications for booking $bookingId');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('DEBUG: Cancelled all notifications');
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Send immediate test notification (for testing on simulator)
  Future<void> sendTestNotification() async {
    await _notifications.show(
      999,
      '🔔 Test Bildirimi',
      'Bildirimler çalışıyor!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'rental_reminders',
          'Kiralama Hatırlatıcıları',
          channelDescription: 'Yaklaşan kiralamalar için hatırlatmalar',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print('DEBUG: Test notification sent!');
  }
}
