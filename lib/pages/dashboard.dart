// // // lib/pages/dashboard.dart

// // lib/pages/dashboard.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services.dart';
// import 'setting.dart';
// import 'certification.dart';
// import 'retirement.dart';
// import 'renewal_screen.dart';
// import 'notification_screen.dart';
// import 'application_list_screen.dart';
// import '../screens/applications_timeline.dart';
// import 'package:flutter/foundation.dart';
// import 'released_certififcates.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});
//   static const String routeName = '/dashboard';

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   String? userId;
//   String? pendingApplicationId;
//   String? currentBusinessName;
//   String? paymentInstruction;
//   String? currentAppStatusDetail;

//   bool _isDataLoading = true;
//   double _appProgress = 0.0;
//   int _unreadNotificationCount = 3;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserId();
//   }

//   Future<void> _loadUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? id = prefs.getString('user_id');
//     id ??= prefs.getInt('user_id')?.toString();

//     if (!mounted) return;
//     setState(() {
//       userId = id;
//       _isDataLoading = false; // Dashboard becomes instantly available
//     });
//   }

  



//   void _navigateToNotifications() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const NotificationScreen()),
//     );

//     if (!mounted) return;
//     setState(() => _unreadNotificationCount = 0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color statusColor = Colors.blueGrey;

//     if (currentAppStatusDetail == 'Pay to the Treasury Office' ||
//         currentAppStatusDetail == 'Ready for Payment') {
//       statusColor = Colors.red;
//     } else if (currentAppStatusDetail == 'Payment Confirmed' ||
//         currentAppStatusDetail == 'Payment Received') {
//       statusColor = Colors.green;
//     }

//     final statusTitle =
//         (pendingApplicationId != null && currentBusinessName != null)
//             ? 'Permit App (${currentBusinessName!} - ID: $pendingApplicationId)'
//             : 'Business Permit Application';

//     return Scaffold(
//       drawer: _buildSidebarMenu(),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1A2B47),
//         title: Row(
//           children: [
//             Image.asset('images/image.png', height: 50),
//             const SizedBox(width: 10),
//             const Text('PermitGO Dashboard',
//                 style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),

//       body: _isDataLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Container(
//               color: Colors.white,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   const Text('Dashboard',
//                       style:
//                           TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 10),

//                   // -------------------------
//                   // MENU BUTTONS
//                   // -------------------------
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.add,
//                                     color: Colors.green, size: 32),
//                                 label: 'New Application',
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (_) =>
//                                             const ApplicationsListScreen()),
//                                   );
//                                 },
//                               ),
//                             ),
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.refresh,
//                                     color: Colors.green, size: 32),
//                                 label: 'Renew',
//                                 onTap: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (_) =>
//                                               const RenewalScreen()));
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.assignment_turned_in,
//                                     color: Colors.green, size: 32),
//                                 label: 'Certification',
//                                 onTap: () {
//                                   Navigator.push(
//                                       context,
//                                          MaterialPageRoute(builder: (_) => const ReleasedCertificatesList()),
//                                         );
//                                 },
//                               ),
//                             ),
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.business_center,
//                                     color: Colors.green, size: 32),
//                                 label: 'Retirement',
//                                 onTap: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (_) =>
//                                               const RetirementDocumentsPage()));
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.notifications,
//                                     color: Colors.blue, size: 32),
//                                 label: 'Notifications',
//                                 onTap: _navigateToNotifications,
//                               ),
//                             ),
//                             Expanded(
//                               child: _buildMenuItem(
//                                 icon: const Icon(Icons.settings,
//                                     color: Colors.green, size: 32),
//                                 label: 'Settings',
//                                 onTap: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (_) =>
//                                               const SettingsScreen()));
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   // -------------------------
//                   // APPLICATION STATUS
//                   // -------------------------
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Application Status",
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 10),

//                         Container(
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(4),
//                               border:
//                                   Border.all(color: Colors.grey.shade300)),
//                           padding: const EdgeInsets.all(12),
//                           child: _buildStatusItem(
//                             title: statusTitle,
//                             status: currentAppStatusDetail ?? 'Loading...',
//                             date: paymentInstruction ?? 'Loading...',
//                             color: statusColor,
//                             progress: _appProgress,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   // ---------------------------------
//   // SIDEBAR
//   // ---------------------------------
//   Drawer _buildSidebarMenu() {
//     return Drawer(
//       child: ListView(
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF1A2B47)),
//             child: Center(
//               child: Text('PermitGO Menu',
//                   style: TextStyle(color: Colors.white, fontSize: 20)),
//             ),
//           ),

//           _drawerItem(Icons.dashboard, 'Dashboard', const DashboardScreen()),
//           _drawerItem(
//               Icons.add, 'New Application', const ApplicationsListScreen()),
//           _drawerItem(Icons.refresh, 'Renewal', const RenewalScreen()),
//           _drawerItem(Icons.assignment_turned_in, 'Certification',
//               MayorsPermitPage()),
//           _drawerItem(Icons.business_center, 'Retirement',
//               const RetirementDocumentsPage()),

//           ListTile(
//             leading:
//                 const Icon(Icons.notifications, color: Color(0xFF1A2B47)),
//             title: const Text('Notifications'),
//             trailing: _unreadNotificationCount > 0
//                 ? CircleAvatar(
//                     radius: 10,
//                     backgroundColor: Colors.red,
//                     child: Text(
//                       '$_unreadNotificationCount',
//                       style:
//                           const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                   )
//                 : null,
//             onTap: _navigateToNotifications,
//           ),

//           _drawerItem(
//               Icons.settings, 'Settings', const SettingsScreen()),
//         ],
//       ),
//     );
//   }

//   ListTile _drawerItem(IconData icon, String title, Widget page) {
//     return ListTile(
//       leading: Icon(icon, color: const Color(0xFF1A2B47)),
//       title: Text(title),
//       onTap: () {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => page),
//         );
//       },
//     );
//   }

//   Widget _buildMenuItem({
//     required Widget icon,
//     required String label,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         children: [
//           SizedBox(height: 48, width: 48, child: Center(child: icon)),
//           const SizedBox(height: 6),
//           Text(label, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusItem({
//     required String title,
//     required String status,
//     required String date,
//     required Color color,
//     required double progress,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(Icons.description,
//                 size: 28, color: Colors.blueGrey),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                           fontSize: 14, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 4),
//                   Text('Status: $status',
//                       style: TextStyle(
//                           color: color, fontWeight: FontWeight.w600)),
//                   Text('Date: $date',
//                       style: const TextStyle(
//                           fontSize: 12, color: Colors.grey)),
//                 ],
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: progress,
//           minHeight: 6,
//           backgroundColor: Colors.grey.shade300,
//           color: color,
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart';
//import 'application.dart';
import 'setting.dart';
import 'certification.dart';
import 'retirement.dart';
import 'renewal_screen.dart';
import 'notification_screen.dart';
import 'application_list_screen.dart';
import '../screens/applications_timeline.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE VARIABLES ---
  String? userId;
  String? pendingApplicationId;
  String? currentBusinessName;
  String? paymentInstruction;
  String? currentAppStatusDetail;

  bool _isDataLoading = true;
  double _appProgress = 0.0;
  int _unreadNotificationCount = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserId();
    // if (userId != null) {
    // //   try {
    // //     // await _loadPendingApplicationId();
    // //     // await _loadApplicationStatusOnly();
    // //   } catch (e) {
    // //     if (kDebugMode) print('Dashboard Load Failed: $e');
    // //   }
    //  }

    if (!mounted) return;
    setState(() => _isDataLoading = false);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('user_id');
    id ??= prefs.getInt('user_id')?.toString();

    if (!mounted) return;
    setState(() => userId = id);
  }

  Future<void> _loadPendingApplicationId() async {
    if (userId == null) return;

    try {
      final response = await ApiService.getPendingApplication(userId!);

      if (response['success'] == true && response['application_id'] != null) {
        if (!mounted) return;
        setState(() {
          pendingApplicationId = response['application_id'].toString();
        });
      } else {
        if (!mounted) return;
        setState(() => pendingApplicationId = null);
      }
    } catch (e) {
      if (kDebugMode) print("Pending Application Error: $e");
      if (!mounted) return;
      setState(() => pendingApplicationId = null);
    }
  }

  Future<void> _loadApplicationStatusOnly() async {
  if (userId == null) return;

  try {
    final response = await ApiService.getApplicationStatus(userId!);

    if (response['success'] == true) {
      if (!mounted) return;

      setState(() {
        currentAppStatusDetail = response['status'];  
        currentBusinessName = response['business_name'];
        pendingApplicationId = response['application_id'].toString();
        _appProgress = (response['progress'] as num).toDouble();
        paymentInstruction = "Status Updated";
      });
    } else {
      if (!mounted) return;
      setState(() {
        currentAppStatusDetail = 'No Active Application';
        pendingApplicationId = null;
        currentBusinessName = null;
        _appProgress = 0.0;
        paymentInstruction = 'Start a New Application';
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      currentAppStatusDetail = 'No Active Application';
      paymentInstruction = 'Could not connect to server';
    });
  }
}

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );

    if (!mounted) return;
    setState(() => _unreadNotificationCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.blueGrey;

    if (currentAppStatusDetail == 'Pay to the Treasury Office' || currentAppStatusDetail == 'Ready for Payment') {
      statusColor = Colors.red;
    } else if (currentAppStatusDetail == 'Payment Confirmed' || currentAppStatusDetail == 'Payment Received') {
      statusColor = Colors.green;
    }

    final statusTitle =
        (pendingApplicationId != null && currentBusinessName != null)
            ? 'Permit App (${currentBusinessName!} - ID: $pendingApplicationId)'
            : 'Business Permit Application';

    return Scaffold(
      drawer: _buildSidebarMenu(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        title: Row(
          children: [
            Image.asset('images/image.png', height: 50),
            const SizedBox(width: 10),
            const Text('PermitGO Dashboard', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),

      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // -------------------------
                  // MENU BUTTONS
                  // -------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.add, color: Colors.green, size: 32),
                                label: 'New Application',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ApplicationsListScreen()),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.refresh, color: Colors.green, size: 32),
                                label: 'Renew',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RenewalScreen()));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 32),
                                label: 'Certification',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => MayorsPermitPage()));
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.business_center, color: Colors.green, size: 32),
                                label: 'Retirement',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RetirementDocumentsPage()));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.notifications, color: Colors.blue, size: 32),
                                label: 'Notifications',
                                onTap: _navigateToNotifications,
                              ),
                            ),
                            Expanded(
                              child: _buildMenuItem(
                                icon: const Icon(Icons.settings, color: Colors.green, size: 32),
                                label: 'Settings',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // -------------------------
                  // APPLICATION STATUS (No Resume, Display Only)
                  // -------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Application Status",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300)),
                          padding: const EdgeInsets.all(12),
                          child: _buildStatusItem(
                            title: statusTitle,
                            status: currentAppStatusDetail ?? 'Loading...',
                            date: paymentInstruction ?? 'Loading...',
                            color: statusColor,
                            progress: _appProgress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------
  // SIDEBAR
  // ---------------------------------
  Drawer _buildSidebarMenu() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1A2B47)),
            child: Center(
              child: Text('PermitGO Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),

          _drawerItem(Icons.dashboard, 'Dashboard', const DashboardScreen()),
          _drawerItem(Icons.add, 'New Application', const ApplicationsListScreen()),
          _drawerItem(Icons.refresh, 'Renewal', const RenewalScreen()),
          _drawerItem(Icons.assignment_turned_in, 'Certification', MayorsPermitPage()),
          _drawerItem(Icons.business_center, 'Retirement', const RetirementDocumentsPage()),

          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF1A2B47)),
            title: const Text('Notifications'),
            trailing: _unreadNotificationCount > 0
                ? CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            onTap: _navigateToNotifications,
          ),

          _drawerItem(Icons.settings, 'Settings', const SettingsScreen()),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A2B47)),
      title: Text(title),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required Widget icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(height: 48, width: 48, child: Center(child: icon)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String status,
    required String date,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description, size: 28, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Status: $status',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  Text('Date: $date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.grey.shade300,
          color: color,
        ),
      ],
    );
  }
}


