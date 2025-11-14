// lib/pages/help_screen.dart

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Documentation", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Section ---
            const Text(
              'Welcome to PermitGO Support',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFF1A2B47)),
            ),
            const SizedBox(height: 8),
            const Text(
              'This guide helps you navigate our business permit and renewal platform. For technical issues, please contact support.',
              style: TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- Main Content Sections ---
            _buildSection(
              context,
              title: '1. New Application Process',
              content: [
                '**Step 1: Start Form:** Tap "New Application" on the Dashboard.',
                '**Step 2: Taxpayer Details:** Fill in your personal and business identification information (TIN, legal name, etc.).',
                '**Step 3: Other Information:** Provide location details, business area, and number of employees.',
                '**Step 4: Business Activity:** Select the primary and secondary activities and input capital details.',
                '**Step 5: Document Upload:** After submission, proceed to upload required supporting documents (DTI, Fire Safety, etc.).',
                '**Step 6: Submission:** Confirm and finalize the application for review by the LGU.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              context,
              title: '2. Renewal and Status Check',
              content: [
                '**Renewals:** Go to the "Renew" section. Only approved and active permits will appear here. Review pre-filled data and upload new annual documents.',
                '**Application Status:** Check the "Application Status" card on the Dashboard for real-time progress updates (Draft, Pending Review, Approved, For Payment).',
                '**Required Documents:** Always ensure documents are in **PDF or JPEG** format, clear, and under 5MB.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              context,
              title: '3. Payments and Certification',
              content: [
                '**Payment:** Once your application status is "Approved" and "For Payment," tap the "Payment" option (if available) or check the **Notifications** screen for a payment link.',
                '**Accepted Methods:** We accept payments via GCash, Maya, and major credit/debit cards.',
                '**Certification:** The "Certification" section allows you to view and download your **Mayor\'s Permit** once the payment is verified and the permit is issued electronically.',
              ],
            ),
            _buildDivider(),

            _buildSection(
              context,
              title: '4. System Requirements & Troubleshooting',
              content: [
                '**OS Compatibility:** Supports Android 8.0+ and iOS 13+.',
                '**Connectivity:** A stable internet connection is required for all application submissions and status checks.',
                '**Troubleshooting:** If you encounter a network error, please try restarting the app and checking your Wi-Fi or mobile data connection.',
              ],
            ),
            
            const SizedBox(height: 40),
            // --- Contact Info ---
            Center(
              child: Text(
                'For immediate assistance, contact our technical team at support@permitgo.ph',
                style: TextStyle(fontSize: 14.0, color: Colors.blue[800], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget to build structured documentation sections ---
  Widget _buildSection(BuildContext context, {required String title, required List<String> content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1A2B47)),
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content
              .map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text('• ${item}', style: TextStyle(fontSize: 14.0, height: 1.4)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Divider(height: 1, color: Colors.grey),
    );
  }
}