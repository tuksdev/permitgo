import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart'; 
import 'application.dart';
import 'setting.dart';
import 'certification.dart';
import 'retirement.dart';
import 'renewal_screen.dart';
import 'notification_screen.dart'; 
import 'dart:async';
import 'payment.dart'; // Ensure PaymentScreen is imported

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
  String? paymentInstruction;     // e.g., 'Payment Due: Jan 17, 2026' or 'Paid on: Nov 10, 2025'
  String? currentAppStatusDetail; // e.g., 'Pay to the Treasury Office', 'Payment Confirmed'
  
  bool _isDataLoading = true;
  double _appProgress = 0.0;
  int _unreadNotificationCount = 3; 

  // --- INITIALIZATION ---
  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  // --- DATA LOADING SEQUENCE (FIXED FOR HANGING) ---
  Future<void> _loadData() async {
    await _loadUserId();
    if (userId != null) {
        try {
            await Future.wait([ /* API calls here */ ]);
        } catch (e) {
            print('Dashboard Load Sequence Failed Gracefully: $e');
        }
    }
    await _loadPendingApplicationId();  
    
    // 3. CRITICAL: Ensure loading state is set to false to draw the UI.
    setState(() {
        _isDataLoading = false;
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _loadPendingApplicationId() async {
    if (userId == null) return; 

    // Fetches the latest application ID for the user
    final response = await ApiService.getPendingApplication(userId!);
    
    if (response['success'] == true && response['application_id'] != null) {
      setState(() {
        pendingApplicationId = response['application_id'].toString(); 
      });
    } else {
      setState(() {
        pendingApplicationId = null;
      });
    }
  }

  // --- CRITICAL: Function to load full status and payment details ---
  Future<void> _loadApplicationAndPaymentStatus() async {
    if (userId == null) return;

    // NOTE: This call uses the user ID to fetch the status of the most relevant application
    // This relies on ApiService having the timeout handling we discussed.
    final response = await ApiService.getApplicationPaymentDetails(userId!);
    
    if (response['success'] == true) {
      final statusDetail = response['status_detail']; 
      final dueDate = response['due_date']; 
      final paymentDate = response['payment_date']; 
      final businessName = response['business_name']; // Fetched business name
      
      setState(() {
        currentAppStatusDetail = statusDetail;
        currentBusinessName = businessName;
        
        // Map the status to the user instruction and progress bar
        if (statusDetail == 'Pay to the Treasury Office') {
            paymentInstruction = 'Payment Due: $dueDate';
            _appProgress = 0.6; 
        } else if (statusDetail == 'Payment Confirmed') {
            paymentInstruction = 'Paid on: $paymentDate';
            _appProgress = 1.0;
        } else if (statusDetail == 'Ready for Tax Assessment') {
            paymentInstruction = 'Awaiting Assessment Data';
            _appProgress = 0.4;
        } else {
            paymentInstruction = 'Processing...';
            _appProgress = 0.2; 
        }
      });
    } else {
       // Handle case where API finds no relevant application or failed due to timeout
       setState(() {
           currentAppStatusDetail = 'No Active Application';
           paymentInstruction = response['message'] ?? 'Start a New Application'; 
           _appProgress = 0.0;
       });
    }
  }
  
  // --- NAVIGATION ---
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
    setState(() {
      _unreadNotificationCount = 0; 
    });
  }
  
  // --- RESUME FEATURE HANDLER ---
  void _resumeApplicationFlow() {
    if (pendingApplicationId == null || currentAppStatusDetail == 'No Active Application') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplicationFormScreen()));
      return;
    }
    
    Widget destinationScreen;
    
    switch (currentAppStatusDetail) {
      case 'Ready for Tax Assessment':
      case 'Pending Review':
        // User needs to check documents or data for the admin.
        destinationScreen = ApplicationFormScreen(applicationId: pendingApplicationId);
        break;

      case 'Pay to the Treasury Office':
        // Assessment is complete. Navigate to the payment view.
        destinationScreen = PaymentScreen(userId: userId!, applicationId: pendingApplicationId!);
        break;
        
      case 'Payment Confirmed':
        // Final status. Show the screen where the user can download the permit/certificate.
        destinationScreen = MayorsPermitPage(applicationId: pendingApplicationId);
        break;

      default:
        destinationScreen = ApplicationFormScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (currentAppStatusDetail == 'Pay to the Treasury Office') {
      statusColor = Colors.red;
    } else if (currentAppStatusDetail == 'Payment Confirmed') {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.blueGrey;
    }
    
    // Set the title for the dynamic status item
    final statusTitle = pendingApplicationId != null && currentBusinessName != null
        ? 'Permit App (${currentBusinessName!} - ID: $pendingApplicationId)' 
        : 'Business Permit Application';

    return Scaffold(
      drawer: _buildSidebarMenu(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        title: Row(
          children: [
            Image.asset('images/image.png', height: 50, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('PermitGO Dashboard', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: _isDataLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A2B47))) 
          : Container(
        color: Colors.white,
        width: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: Column(
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 3.0,
                    width: 120.0,
                    color: Colors.blue,
                    margin: const EdgeInsets.only(top: 4.0),
                  ),
                ],
              ),
            ),
            
            // Grid Menu (Your existing structure)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.add, color: Colors.green, size: 32.0), label: 'New Application', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplicationFormScreen())); })),
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.refresh, color: Colors.green, size: 28.0), label: 'Renew', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RenewalScreen())); })),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 32.0), label: 'Certification', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => MayorsPermitPage())); })),
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.business_center, color: Colors.green, size: 32.0), label: 'Retirement', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RetirementDocumentsPage())); })),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.notifications, color: Colors.blue, size: 32.0), label: 'Notifications', onTap: _navigateToNotifications)),
                      Expanded(child: _buildMenuItem(icon: const Icon(Icons.settings, color: Colors.green, size: 28.0), label: 'Settings', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); })),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Container(height: 1, color: Colors.grey[300]),
            ),

            // ✅ Application Status Section (Updated to use fetched data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: ListView(
                          children: [
                            // --- Status Item is now clickable to resume flow ---
                            InkWell(
                              onTap: _resumeApplicationFlow,
                              child: _buildStatusItem(
                                title: statusTitle,
                                status: currentAppStatusDetail ?? 'Loading Status...', 
                                date: paymentInstruction ?? 'Loading Details...', 
                                color: statusColor,
                                progress: _appProgress,
                              ),
                            ),
                            // --- Placeholder for other items removed ---
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS (Your Existing Structure) ---
  
  Drawer _buildSidebarMenu(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1A2B47)),
            child: Center(
              child: Text('PermitGO Menu', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
          _drawerItem(context, Icons.dashboard, 'Dashboard', const DashboardScreen()),
          _drawerItem(context, Icons.add, 'New Application', const ApplicationFormScreen()),
          _drawerItem(context, Icons.refresh, 'Renewal', RenewalScreen()),
          _drawerItem(context, Icons.assignment_turned_in, 'Certification', MayorsPermitPage()),
          _drawerItem(context, Icons.business_center, 'Retirement', const RetirementDocumentsPage()),
          
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF1A2B47)),
            title: const Text('Notifications'),
            trailing: _unreadNotificationCount > 0 
                ? Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              _navigateToNotifications();
            },
          ),
          _drawerItem(context, Icons.settings, 'Settings', const SettingsScreen()),
        ],
      ),
    );
  }

  ListTile _drawerItem(BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A2B47)),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  Widget _buildMenuItem({required Widget icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(height: 48, width: 48, child: Center(child: icon)),
          const SizedBox(height: 6.0),
          Text(label, style: const TextStyle(fontSize: 12.0)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.description, color: Colors.blueGrey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                  const SizedBox(height: 4),
                  Text('Status: $status', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  Text('Date: $date', style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 6,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildNotificationAction() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 26),
          onPressed: _navigateToNotifications,
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$_unreadNotificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services.dart'; // Import ApiService

// import 'application.dart';
// import 'setting.dart';
// import 'certification.dart';
// import 'retirement.dart';
// import 'renewal_screen.dart';
// import 'payment.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});
//   static const String routeName = '/dashboard';

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   String? userId;
//   String? pendingApplicationId; // Stores the fetched ID (e.g., '12345')
//   bool _isDataLoading = true; // Tracks if initial data fetch is complete

//   @override
//   void initState() {
//     super.initState();
//     _loadData(); // Load user ID and pending application ID
//   }

//   // Combines loading user ID and pending application ID
//   Future<void> _loadData() async {
//     await _loadUserId();
//     if (userId != null) {
//       await _loadPendingApplicationId();
//     }
//     setState(() {
//       _isDataLoading = false; // Data is ready
//     });
//   }

//   Future<void> _loadUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       userId = prefs.getString('user_id');
//     });
//   }

//   // Fetches the application_id from the Python backend
//   Future<void> _loadPendingApplicationId() async {
//     if (userId == null) return; 

//     final response = await ApiService.getPendingApplication(userId!);
    
//     if (response['success'] == true && response['application_id'] != null) {
//       setState(() {
//         // ID is fetched as a string (e.g., '16')
//         pendingApplicationId = response['application_id']; 
//       });
//     } else {
//       setState(() {
//         pendingApplicationId = null;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: _buildSidebarMenu(context),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1A2B47),
//         title: Row(
//           children: [
//             Image.asset('images/image.png', height: 50, fit: BoxFit.contain),
//             const SizedBox(width: 10),
//             const Text('PermitGO Dashboard'),
//           ],
//         ),
//       ),
//       // Display loading screen if data is not ready
//       body: _isDataLoading 
//           ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A2B47))) 
//           : Container(
//         color: Colors.white,
//         width: double.infinity,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Dashboard',
//                     style: TextStyle(
//                       fontSize: 22.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Container(
//                     height: 3.0,
//                     width: 120.0,
//                     color: Colors.blue,
//                     margin: const EdgeInsets.only(top: 4.0),
//                   ),
//                 ],
//               ),
//             ),

//             // ✅ Grid Menu
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.add, color: Colors.green, size: 32.0),
//                           label: 'New Application',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const ApplicationFormScreen()),
//                             );
//                           },
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.refresh, color: Colors.green, size: 28.0),
//                           label: 'Renew',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => RenewalScreen()),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24.0),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 32.0),
//                           label: 'Certification',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => MayorsPermitPage()),
//                             );
//                           },
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.business_center, color: Colors.green, size: 32.0),
//                           label: 'Retirement',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const RetirementDocumentsPage()),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24.0),

//                   // ✅ Payment + Settings Row (GRID MENU)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.payment, color: Colors.green, size: 32.0),
//                           label: 'Payment',
//                           onTap: () {
//   if (userId == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('User not found. Please log in again.')),
//     );
//   } else {
//     // --- TEMPORARY FIX FOR TESTING ---
//     const String testApplicationId = '123456'; // Use a simple, numeric string

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PaymentScreen(
//           userId: userId!, 
//           applicationId: testApplicationId, // PASSES THE HARDCODED TEST ID
//         ),
//       ),
//     );
//     // --- END TEMPORARY FIX ---
//   }
// },
//                         ),
//                       ),
//                       Expanded(
//                         child: _buildMenuItem(
//                           icon: const Icon(Icons.settings, color: Colors.green, size: 28.0),
//                           label: 'Settings',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const SettingsScreen()),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
//               child: Container(height: 1, color: Colors.grey[300]),
//             ),

//             // ✅ Application Status Section
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Application Status',
//                       style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12.0),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(12.0),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(4.0),
//                         ),
//                         child: ListView(
//                           children: [
//                             _buildStatusItem(
//                               title: 'Business Permit Application',
//                               status: 'Pending Review',
//                               date: 'May 10, 2025',
//                               color: Colors.orange,
//                               progress: 0.4,
//                             ),
//                             _buildStatusItem(
//                               title: 'Renewal Request',
//                               status: 'Approved',
//                               date: 'May 5, 2025',
//                               color: Colors.green,
//                               progress: 1.0,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ Sidebar Menu
//   Drawer _buildSidebarMenu(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(color: Color(0xFF1A2B47)),
//             child: Center(
//               child: Text('PermitGO Menu', style: TextStyle(color: Colors.white, fontSize: 20)),
//             ),
//           ),
//           _drawerItem(context, Icons.dashboard, 'Dashboard', const DashboardScreen()),
//           _drawerItem(context, Icons.add, 'New Application', const ApplicationFormScreen()),
//           _drawerItem(context, Icons.refresh, 'Renewal', RenewalScreen ()),
//           _drawerItem(context, Icons.assignment_turned_in, 'Certification', MayorsPermitPage()),
//           _drawerItem(context, Icons.business_center, 'Retirement', const RetirementDocumentsPage()),
          
//           // --- PAYMENT LIST TILE FIX ---
//           ListTile(
//             leading: const Icon(Icons.payment, color: Color(0xFF1A2B47)),
//             title: const Text('Payment'),
//             onTap: () {
//               if (userId == null) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('User not found. Please log in again.')),
//                 );
//               } else if (pendingApplicationId == null) {
//                  ScaffoldMessenger.of(context).showSnackBar(
//                    const SnackBar(content: Text('No approved application found requiring payment.')),
//                  );
//               } else {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     // PASSES THE FETCHED ID
//                     builder: (context) => PaymentScreen(userId: userId!, applicationId: pendingApplicationId!)),
//                 );
//               }
//             },
//           ),
//           _drawerItem(context, Icons.settings, 'Settings', const SettingsScreen()),
//         ],
//       ),
//     );
//   }

//   ListTile _drawerItem(BuildContext context, IconData icon, String label, Widget page) {
//     return ListTile(
//       leading: Icon(icon, color: const Color(0xFF1A2B47)),
//       title: Text(label),
//       onTap: () {
//         Navigator.pop(context);
//         Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//       },
//     );
//   }

//   Widget _buildMenuItem({required Widget icon, required String label, VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         children: [
//           SizedBox(height: 48, width: 48, child: Center(child: icon)),
//           const SizedBox(height: 6.0),
//           Text(label, style: const TextStyle(fontSize: 12.0)),
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
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Icon(Icons.description, color: Colors.blueGrey, size: 28),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
//                   const SizedBox(height: 4),
//                   Text('Status: $status', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
//                   Text('Date: $date', style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         LinearProgressIndicator(
//           value: progress,
//           backgroundColor: Colors.grey[300],
//           color: color,
//           minHeight: 6,
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
// }
