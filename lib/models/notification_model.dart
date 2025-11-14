// lib/models/notification_model.dart

class NotificationModel {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false, // Default is unread
  });
}