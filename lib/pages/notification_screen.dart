// lib/pages/notification_screen.dart

import 'package:flutter/material.dart';
import '../models/notification_model.dart'; // 🛑 Import the data model

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 💡 Sample data with mixed read/unread states
  final List<NotificationModel> _notifications = [
    NotificationModel(
      title: 'Application Approved! 🎉',
      body: 'Your Business Permit Application #2025-101 has been officially approved.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationModel(
      title: 'Action Required: Document Upload',
      body: 'Please upload the latest Barangay Clearance document for renewal.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      title: 'Welcome to the Platform!',
      body: 'Thank you for registering. You can now start a new application.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true, // Already read
    ),
    NotificationModel(
      title: 'New Feature Alert',
      body: 'We have launched Gcash payment integration for faster transactions.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  // --- Function to handle tapping a notification ---
  void _markAsRead(int index) {
    if (!_notifications[index].isRead) {
      setState(() {
        // Change the state of the specific notification item
        _notifications[index].isRead = true;
      });
      // Optionally navigate to a detail screen or take other action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification marked as read: ${_notifications[index].title}')),
      );
    }
  }
  
  // --- Helper to format the time since the notification was sent ---
  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort notifications to show unread first
    _notifications.sort((a, b) => a.isRead == b.isRead ? b.timestamp.compareTo(a.timestamp) : a.isRead ? 1 : -1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text("You have no notifications.", style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                
                // Determine the style based on the read status
                final bool isUnread = !notification.isRead;
                final TextStyle titleStyle = TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread ? Colors.black : Colors.grey[700],
                );
                final Color tileColor = isUnread ? const Color(0xFFE3F2FD) : Colors.white; // Light blue background for unread

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  elevation: 0, // Flat card for list appearance
                  color: tileColor,
                  child: ListTile(
                    // 🔴 Indicator for Unread Notification 🔴
                    leading: isUnread
                        ? const Icon(Icons.circle, size: 10, color: Colors.red) // Red dot indicator
                        : const Icon(Icons.notifications_none, color: Colors.grey),
                    
                    title: Text(
                      notification.title,
                      style: titleStyle,
                    ),
                    subtitle: Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      _timeAgo(notification.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? Colors.red : Colors.grey,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _markAsRead(index),
                  ),
                );
              },
            ),
    );
  }
}