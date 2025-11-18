// lib/models/notification_model.dart
class NotificationModel {
  final int id;
  final String title; // category name
  final String body; // custom_message or category template
  final DateTime timestamp;
  bool isRead;
  final String? categoryName;
  final int? categoryId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.categoryName,
    this.categoryId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // backend returns created_at as ISO or datetime string; handle both
    DateTime ts;
    try {
      ts = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      ts = DateTime.now();
    }

    // Some rows may have 'custom_message' null; pick template when available.
    final body = (json['custom_message'] ?? json['message_template'] ?? '').toString();

    return NotificationModel(
      id: json['notification_id'] is int ? json['notification_id'] : int.parse(json['notification_id'].toString()),
      title: (json['category_name'] ?? 'Notification').toString(),
      body: body,
      timestamp: ts,
      isRead: (json['is_read'] == 1 || json['is_read'] == true),
      categoryName: json['category_name']?.toString(),
      categoryId: json['category_id'] is int ? json['category_id'] : (json['category_id'] != null ? int.parse(json['category_id'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'category_name': title,
      'custom_message': body,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'category_id': categoryId,
    };
  }
}
