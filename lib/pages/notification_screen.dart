// // lib/pages/notification_screen.dart

// lib/pages/notification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../api_services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<NotificationModel> _notifications = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _page = 1;
  final int _pageSize = 20;

  late ScrollController _scrollController;
  String? _userId;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _initAndLoad();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    //_userId = prefs.getInt("user_id");

    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }

    await _refresh();

    // Fetch unread count
    final count = await ApiService.getUnreadCount(_userId!);
    setState(() => _unreadCount = count);
  }

  // -------------------------------
  // 🔥 FIXED REFRESH METHOD
  // -------------------------------
  Future<void> _refresh() async {
    if (_userId == null) return;

    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });

    final result = await ApiService.fetchNotificationsPaginated(
      userId: _userId!,
      page: _page,
      pageSize: _pageSize,
    );

    if (result['success'] == true) {

      // Convert list of JSON → List<NotificationModel>
      final items = (result['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      setState(() {
        _notifications
          ..clear()
          ..addAll(items);

        _hasMore = result['hasMore'];
        _loading = false;
      });

      // Update unread badge
      final count = await ApiService.getUnreadCount(_userId!);
      setState(() => _unreadCount = count);
    } else {
      setState(() => _loading = false);
    }
  }

  // -------------------------------
  // 🔥 FIXED PAGINATION
  // -------------------------------
  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;

    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_userId == null) return;

    setState(() => _loadingMore = true);
    _page += 1;

    final result = await ApiService.fetchNotificationsPaginated(
      userId: _userId!,
      page: _page,
      pageSize: _pageSize,
    );

    if (result['success'] == true) {
      final items = (result['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      setState(() {
        _notifications.addAll(items);
        _hasMore = result['hasMore'];
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  // -------------------------------
  // MARK AS READ
  // -------------------------------
  Future<void> _markAsReadLocalAndServer(int index) async {
    final n = _notifications[index];
    if (n.isRead) return;

    // Optimistic update
    setState(() {
      _notifications[index].isRead = true;
      if (_unreadCount > 0) _unreadCount -= 1;
    });

    // Update server
    final success = await ApiService.markNotificationRead(n.id);

    if (!success) {
      // Rollback if failed
      setState(() {
        _notifications[index].isRead = false;
        _unreadCount += 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark as read on server')),
      );
    }
  }

  // -------------------------------
  // TIME AGO FORMATTER
  // -------------------------------
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  // -------------------------------
  // UI BUILD
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: const Color(0xFF1A2B47),
          actions: [
            if (_unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF1A2B47),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Text(
                  'Unread: $_unreadCount',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Text(
                      "You have no notifications.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _notifications.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final n = _notifications[index];
                  final isUnread = !n.isRead;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 0,
                    color: isUnread ? const Color(0xFFEFF7FF) : Colors.white,
                    child: ListTile(
                      leading: isUnread
                          ? const Icon(Icons.circle,
                              size: 10, color: Colors.red)
                          : const Icon(Icons.notifications_outlined),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                          color: isUnread ? Colors.black : Colors.grey[700],
                        ),
                      ),
                      subtitle: Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _timeAgo(n.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? Colors.red : Colors.grey,
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _markAsReadLocalAndServer(index),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/notification_model.dart';
// import '../api_services.dart'; // adjust path

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   final List<NotificationModel> _notifications = [];
//   bool _loading = true;
//   bool _loadingMore = false;
//   bool _hasMore = true;
//   int _page = 1;
//   final int _pageSize = 20;
//   late ScrollController _scrollController;
//   int? _userId;
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController()..addListener(_onScroll);
//     _initAndLoad();
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _initAndLoad() async {
//     final prefs = await SharedPreferences.getInstance();
//     _userId = prefs.getInt("user_id");
//     if (_userId == null) {
//       setState(() {
//         _loading = false;
//       });
//       return;
//     }

//     await _refresh(); // initial load
//     // optionally fetch unread count
//     final count = await ApiService.getUnreadCount(_userId!);
//     setState(() => _unreadCount = count);
//   }

//   Future<void> _refresh() async {
//     if (_userId == null) return;
//     setState(() {
//       _loading = true;
//       _page = 1;
//       _hasMore = true;
//     });

//     final result = await ApiService.fetchNotificationsPaginated(userId: _userId!, page: _page, pageSize: _pageSize);
//     if (result['success'] == true) {
//       final List<NotificationModel> items = List<NotificationModel>.from(result['notifications'] as List);
//       setState(() {
//         _notifications.clear();
//         _notifications.addAll(items);
//         _hasMore = result['hasMore'];
//         _loading = false;
//       });
//     } else {
//       setState(() => _loading = false);
//     }
//   }

//   void _onScroll() {
//     if (!_hasMore || _loadingMore || _loading) return;
//     if (_scrollController.position.pixels > (_scrollController.position.maxScrollExtent - 200)) {
//       _loadMore();
//     }
//   }

//   Future<void> _loadMore() async {
//     if (_userId == null) return;
//     setState(() => _loadingMore = true);
//     _page += 1;
//     final result = await ApiService.fetchNotificationsPaginated(userId: _userId!, page: _page, pageSize: _pageSize);
//     if (result['success'] == true) {
//       final List<NotificationModel> items = List<NotificationModel>.from(result['notifications'] as List);
//       setState(() {
//         _notifications.addAll(items);
//         _hasMore = result['hasMore'];
//         _loadingMore = false;
//       });
//     } else {
//       setState(() => _loadingMore = false);
//     }
//   }

//   Future<void> _markAsReadLocalAndServer(int index) async {
//     final n = _notifications[index];
//     if (n.isRead) return;

//     // Optimistic UI update
//     setState(() {
//       _notifications[index].isRead = true;
//       _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
//     });

//     // Fire & forget write to server (await but don't block UI)
//     final success = await ApiService.markNotificationRead(n.id);
//     if (!success) {
//       // If failed, roll back locally (optional)
//       setState(() {
//         _notifications[index].isRead = false;
//         _unreadCount += 1;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to mark as read on server')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Marked as read: ${n.title}')),
//       );
//     }
//   }

//   String _timeAgo(DateTime date) {
//     final diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
//     if (diff.inHours < 24) return "${diff.inHours}h ago";
//     return "${diff.inDays}d ago";
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text("Notifications"),
//           backgroundColor: const Color(0xFF1A2B47),
//           actions: [
//             if (_unreadCount > 0)
//               Padding(
//                 padding: const EdgeInsets.only(right: 16.0),
//                 child: Center(child: Text('$_unreadCount', style: const TextStyle(color: Colors.white))),
//               )
//           ],
//         ),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Notifications"),
//         backgroundColor: const Color(0xFF1A2B47),
//         actions: [
//           if (_unreadCount > 0)
//             Padding(
//               padding: const EdgeInsets.only(right: 12.0),
//               child: Center(child: Text('Unread: $_unreadCount', style: const TextStyle(color: Colors.white))),
//             )
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refresh,
//         child: _notifications.isEmpty
//             ? ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 children: const [
//                   SizedBox(height: 150),
//                   Center(child: Text("You have no notifications.", style: TextStyle(color: Colors.grey))),
//                 ],
//               )
//             : ListView.builder(
//                 controller: _scrollController,
//                 itemCount: _notifications.length + (_hasMore ? 1 : 0),
//                 itemBuilder: (context, index) {
//                   if (index >= _notifications.length) {
//                     // Loading indicator at list bottom
//                     return const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       child: Center(child: CircularProgressIndicator()),
//                     );
//                   }

//                   final n = _notifications[index];
//                   final isUnread = !n.isRead;

//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     elevation: 0,
//                     color: isUnread ? const Color(0xFFEFF7FF) : Colors.white,
//                     child: ListTile(
//                       leading: isUnread ? const Icon(Icons.circle, size: 10, color: Colors.red) : const Icon(Icons.notifications_outlined),
//                       title: Text(
//                         n.title,
//                         style: TextStyle(
//                           fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                           color: isUnread ? Colors.black : Colors.grey[700],
//                         ),
//                       ),
//                       subtitle: Text(
//                         n.body,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       trailing: Text(
//                         _timeAgo(n.timestamp),
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: isUnread ? Colors.red : Colors.grey,
//                           fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                       onTap: () => _markAsReadLocalAndServer(index),
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }
