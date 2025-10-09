import 'package:flutter/material.dart';
import 'application.dart';
import 'setting.dart';
import 'certification.dart';
import 'retirement.dart';
import 'renewal.dart';
// import 'application/application1.dart';
// import '../pages/applicationform.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        automaticallyImplyLeading: false,
        title: Image.asset(
          'images/image.png',
          height: 90,
          fit: BoxFit.contain,
        ),
        actions: [
  IconButton(
    icon: const Icon(Icons.payment),
    tooltip: 'Make Payment',
    onPressed: () {
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentScreen(), 
        ),
      );
    },
  ),
],
        centerTitle: false,
      ),
      body: Container(
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
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
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

           
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.green,
                            size: 32.0,
                          ),
                          label: 'New Application',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApplicationFormScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildMenuItem(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.green,
                            size: 28.0,
                          ),
                          label: 'Renew',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationDocumentsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 32.0),
                          label: 'Certification',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MayorsPermitPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildMenuItem(
                          icon: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'RETIRE',
                                style: TextStyle(
                                  fontSize: 6.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          label: 'Retirement',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>const RetirementDocumentsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color:Colors.green,
                            size: 28.0,
                          ),
                          label: 'Notification',
                          onTap: () {},
                        ),
                      ),
                      Expanded(
                        child: _buildMenuItem(
                          icon: const Icon(
                            Icons.settings,
                            color:Colors.green,
                            size: 28.0,
                          ),
                          label: 'Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Container(
                height: 1,
                color: Colors.grey[300],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
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
                            _buildStatusItem(
                              title: 'Business Permit Application',
                              status: 'Pending Review',
                              date: 'May 10, 2025',
                              color: Colors.orange,
                              progress: 0.4,
                            ),
                            _buildStatusItem(
                              title: 'Renewal Request',
                              status: 'Approved',
                              date: 'May 5, 2025',
                              color: Colors.green,
                              progress: 1.0,
                            ),
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
      bottomNavigationBar: Container(
        height: 40.0,
        color: const Color(0xFF1A2B47),
      ),
    );
  }

  /// Menu item builder
  Widget _buildMenuItem({
    required Widget icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: Center(child: icon),
          ),
          const SizedBox(height: 6.0),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
            ),
          ),
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
            Icon(Icons.description, color: Colors.blueGrey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Date: $date',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
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
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: const Center(
        child: Text(
          'Payment Page (To be implemented)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
