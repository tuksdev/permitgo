// lib/pages/settings.dart (Updated)

import 'package:flutter/material.dart';
import 'package:permitgo/pages/help_screen.dart';
import 'signin.dart'; 
import 'faq_screen.dart'; // 🛑 NEW IMPORT: The screen with the questions
import 'help_screen.dart'; // 🛑 NEW IMPORT: The Help screen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ... (Logout logic remains the same) ...

  void _showLogoutConfirmation() { /* ... */ }
  void _logout() { /* ... */ }

  // --- Navigation Function ---
  void _navigateToFaqs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaqScreen(), // Navigate to the new screen
      ),
    );
  }
  
  //---Navigation Function ---
  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpScreen(), // Navigate to the new screen
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- General Settings / Support Section ---
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF1A2B47)),
            ),
            const SizedBox(height: 16),

            // 🛑 FAQs BUTTON/TILE 🛑
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFF1A2B47)),
                title: const Text('Frequently Asked Questions (FAQs)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _navigateToFaqs,
              ),
            ),

            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF1A2B47)),
                title: const Text('Help & Documentation'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _navigateToHelp,
              ),
            ),
            const Divider(height: 30),

            // --- User Session / Logout Section ---
            const Text(
              'User Session',
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF1A2B47)),
            ),
            const SizedBox(height: 16),
            
            // Log Out Button (Retained)
            ElevatedButton.icon(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 202, 25, 25),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'signin.dart'; // Replace this with your actual SignIn page import

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   _SettingsScreenState createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // Show confirmation before logging out
//   void _showLogoutConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Confirm Logout"),
//         content: const Text("Are you sure you want to log out?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(), // Cancel
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); 
//               _logout(); 
//             },
//             child: const Text(
//               "Log Out",
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _logout() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const SignInPage()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Settings"),
//         backgroundColor: const Color(0xFF1A2B47),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text(
//               'Account Settings',
//               style: TextStyle(
//                 fontSize: 22.0,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Change Email Field
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: 'Change Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Change Password Field
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: 'Change Password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Save Changes Button
//             ElevatedButton(
//               onPressed: () {
//                 // Implement logic here to update email/password
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A2B47),
//                 minimumSize: const Size(double.infinity, 48),
//               ),
//               child: const Text('Save Changes'),
//             ),
//             const SizedBox(height: 16),

//             // Log Out Button
//             ElevatedButton.icon(
//               onPressed: _showLogoutConfirmation,
//               icon: const Icon(Icons.logout),
//               label: const Text('Log Out', style: TextStyle(color: Colors.black)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 202, 25, 25),
//                 minimumSize: const Size(double.infinity, 48),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
