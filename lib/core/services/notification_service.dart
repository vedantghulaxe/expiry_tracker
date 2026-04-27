import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Stub notification service — replace with flutter_local_notifications when ready
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void showNotification(String title, String body) {
    LoggerService.info('NOTIFICATION', '$title: $body');
  }
}
