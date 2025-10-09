import 'package:flutter/material.dart';
import '../api_service.dart';
import 'signin.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  // Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final mobileNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sign Up", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 50, 76, 89),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Create an Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
            TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
            TextField(controller: middleNameController, decoration: const InputDecoration(labelText: 'Middle Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            TextField(controller: mobileNumberController, decoration: const InputDecoration(labelText: 'Mobile Number')),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match")),
                  );
                  return;
                }

                final result = await ApiService.signup(
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  middleName: middleNameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  mobileNumber: mobileNumberController.text,
                );

                if (result["error"] != null) {
                  if (result["error"] == "Email already exists") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email already registered. Redirecting to Sign In...")),
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to sign up: ${result["error"]}")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registered successfully! Redirecting to Sign In...")),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 50, 76, 89),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// // import 'dart:convert';

// class SignUpPage extends StatelessWidget {
//   const SignUpPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white, // full white background
//       appBar: AppBar(
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(color: Colors.white), // make AppBar title white
//         ),
//         backgroundColor: const Color.fromARGB(255, 50, 76, 89), // Dark background to show white text
//         iconTheme: const IconThemeData(color: Colors.white), // Make back arrow white
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const SizedBox(height: 10),
//             const Text(
//               "Create an Account",
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             TextField(decoration: const InputDecoration(labelText: 'First Name')),
//             const SizedBox(height: 10),
//             TextField(decoration: const InputDecoration(labelText: 'Last Name')),
//             const SizedBox(height: 10),
//             TextField(decoration: const InputDecoration(labelText: 'Middle Name')),
//             const SizedBox(height: 10),
//             TextField(decoration: const InputDecoration(labelText: 'Email Address')),
//             const SizedBox(height: 10),
//             TextField(
//               obscureText: true,
//               decoration: const InputDecoration(labelText: 'Password'),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               obscureText: true,
//               decoration: const InputDecoration(labelText: 'Confirm Password'),
//             ),
//             const SizedBox(height: 10),
//             TextField(decoration: const InputDecoration(labelText: 'Mobile Number')),

//             const SizedBox(height: 30),

//             ElevatedButton(
//               onPressed: () {
//                 // Sign up logic here
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 50, 76, 89),
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//               ),
//               child: const Text(
//                 "Sign Up",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),

//             // Cancel Button
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text(
//                 "Cancel",
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }