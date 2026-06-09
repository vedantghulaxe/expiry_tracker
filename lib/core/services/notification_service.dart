import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/models/product_info.dart';

/// Notification Service for Expiry Reminders
/// Handles scheduling and displaying notifications for expiring products/medicines
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      await _requestPermissions();

      _isInitialized = true;
      LoggerService.success('NOTIFICATION', 'Notification service initialized');
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to initialize: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      LoggerService.warning('NOTIFICATION', 'Permission request failed: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    LoggerService.info('NOTIFICATION', 'Notification tapped: ${response.payload}');
    // TODO: Navigate to specific product/medicine details
  }

  /// Schedule expiry notifications for a product/medicine
  Future<void> scheduleExpiryNotifications(ProductInfo item) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (item.expiryDate == null) {
      LoggerService.warning('NOTIFICATION', 'No expiry date for ${item.name}');
      return;
    }

    try {
      final now = DateTime.now();
      final expiryDate = item.expiryDate!;
      final daysUntilExpiry = expiryDate.difference(now).inDays;

      LoggerService.info('NOTIFICATION', 'Scheduling notifications for ${item.name}');
      LoggerService.info('NOTIFICATION', 'Expiry date: $expiryDate');
      LoggerService.info('NOTIFICATION', 'Days until expiry: $daysUntilExpiry');

      // Cancel any existing notifications for this item
      if (item.id != null) {
        await cancelNotifications(item.id!);
      }

      // Schedule notifications at different intervals
      final notificationSchedule = [
        {'days': 30, 'title': '30 Days Until Expiry', 'priority': 'low'},
        {'days': 14, 'title': '2 Weeks Until Expiry', 'priority': 'default'},
        {'days': 7, 'title': '1 Week Until Expiry', 'priority': 'high'},
        {'days': 3, 'title': '3 Days Until Expiry', 'priority': 'high'},
        {'days': 1, 'title': 'Expires Tomorrow!', 'priority': 'max'},
        {'days': 0, 'title': 'Expires Today!', 'priority': 'max'},
      ];

      int scheduledCount = 0;
      for (final schedule in notificationSchedule) {
        final daysBeforeExpiry = schedule['days'] as int;
        final notificationDate = expiryDate.subtract(Duration(days: daysBeforeExpiry));

        // Only schedule if notification date is in the future
        if (notificationDate.isAfter(now)) {
          final notificationId = _generateNotificationId(item.id ?? 0, daysBeforeExpiry);
          
          await _scheduleNotification(
            id: notificationId,
            title: schedule['title'] as String,
            body: '${item.name}${item.brand != null ? ' (${item.brand})' : ''} ${daysBeforeExpiry == 0 ? 'expires today' : 'will expire in $daysBeforeExpiry day${daysBeforeExpiry == 1 ? '' : 's'}'}',
            scheduledDate: notificationDate,
            priority: schedule['priority'] as String,
            isMedicine: item.category?.toLowerCase().contains('medicine') ?? false,
            payload: 'item_${item.id}',
          );

          scheduledCount++;
          LoggerService.info('NOTIFICATION', 'Scheduled: ${schedule['title']} for $notificationDate');
        }
      }

      LoggerService.success('NOTIFICATION', 'Scheduled $scheduledCount notifications for ${item.name}');
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to schedule notifications: $e');
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String priority,
    required bool isMedicine,
    String? payload,
  }) async {
    try {
      // Set notification time to 9:00 AM
      final notificationTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9, // 9 AM
        0,
      );

      final scheduledTz = tz.TZDateTime.from(notificationTime, tz.local);

      // Android notification details
      final Color notificationColor = isMedicine ? const Color(0xFFFF5252) : const Color(0xFF2196F3);
      
      final androidDetails = AndroidNotificationDetails(
        isMedicine ? 'medicine_expiry' : 'product_expiry',
        isMedicine ? 'Medicine Expiry Alerts' : 'Product Expiry Alerts',
        channelDescription: isMedicine 
            ? 'Notifications for expiring medicines'
            : 'Notifications for expiring products',
        importance: _getImportance(priority),
        priority: _getPriority(priority),
        icon: '@mipmap/ic_launcher',
        color: notificationColor,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to schedule notification $id: $e');
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    bool isMedicine = false,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final Color notificationColor = isMedicine ? const Color(0xFFFF5252) : const Color(0xFF2196F3);
      
      final androidDetails = AndroidNotificationDetails(
        isMedicine ? 'medicine_expiry' : 'product_expiry',
        isMedicine ? 'Medicine Expiry Alerts' : 'Product Expiry Alerts',
        channelDescription: isMedicine 
            ? 'Notifications for expiring medicines'
            : 'Notifications for expiring products',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: notificationColor,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      LoggerService.info('NOTIFICATION', 'Showed notification: $title');
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to show notification: $e');
    }
  }

  /// Cancel notifications for a specific item
  Future<void> cancelNotifications(int itemId) async {
    try {
      // Cancel all notification variants for this item
      final daysVariants = [30, 14, 7, 3, 1, 0];
      for (final days in daysVariants) {
        final notificationId = _generateNotificationId(itemId, days);
        await _notifications.cancel(notificationId);
      }
      LoggerService.info('NOTIFICATION', 'Cancelled notifications for item $itemId');
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to cancel notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      LoggerService.info('NOTIFICATION', 'Cancelled all notifications');
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      LoggerService.error('NOTIFICATION', 'Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(int itemId, int daysBeforeExpiry) {
    // Combine item ID and days to create unique ID
    // Format: [itemId][days] (e.g., item 5, 7 days = 507)
    return (itemId * 100) + daysBeforeExpiry;
  }

  /// Get Android importance level
  Importance _getImportance(String priority) {
    switch (priority) {
      case 'max':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'default':
        return Importance.defaultImportance;
      case 'low':
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Get Android priority level
  Priority _getPriority(String priority) {
    switch (priority) {
      case 'max':
        return Priority.max;
      case 'high':
        return Priority.high;
      case 'default':
        return Priority.defaultPriority;
      case 'low':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }
}

