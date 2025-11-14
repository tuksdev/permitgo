import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_services.dart';

class PaymentScreen extends StatefulWidget {
  final String userId;
  final String applicationId; // Received from Dashboard

  const PaymentScreen({
    super.key,
    required this.userId,
    required this.applicationId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;

  Future<void> _createPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.createPayment({
      'user_id': widget.userId,
      'application_id': widget.applicationId,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'amount': _amountController.text, // Server converts to float
    });

    setState(() => _isLoading = false);

    if (response['success'] == true && response['checkout_url'] != null) {
      final checkoutUrl = response['checkout_url'];
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(
          Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page')),
        );
      }
    } else {
      final errorMessage =
          response['message'] ?? response['error'] ?? 'Payment creation failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Online (via Maya Sandbox)'),
        backgroundColor: const Color(0xFF1A2B47),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your payment details below:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₱)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 25),

              // Proceed Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2B47),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Proceed to Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../api_service.dart';
// class PaymentScreen extends StatefulWidget {
//   final String userId;
//   final String applicationId; // Received from Dashboard

//   const PaymentScreen({super.key, required this.userId, required this.applicationId});

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _amountController = TextEditingController();

//   bool _isLoading = false;

//   Future<void> _createPayment() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     final response = await ApiService.createPayment({
//       'user_id': widget.userId,
//       'application_id': widget.applicationId, // <--- **CRITICAL FIX: APPLICATION ID ADDED TO PAYLOAD**
//       'first_name': _firstNameController.text,
//       'last_name': _lastNameController.text,
//       'email': _emailController.text,
//       'phone': _phoneController.text,
//       'amount': _amountController.text, // Sent as string; server converts to float
//     });

//     setState(() => _isLoading = false);

//     // Note: The server returns 'checkout_url', not 'redirectUrl'
//     if (response['success'] == true && response['checkout_url'] != null) {
//       final checkoutUrl = response['checkout_url'];
//       if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
//         await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not open payment page')),
//         );
//       }
//     } else {
//       // Display specific message from the server (e.g., validation failure)
//       final errorMessage = response['message'] ?? response['error'] ?? 'Payment creation failed';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage)),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _amountController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pay Online (via Maya Sandbox)'),
//         backgroundColor: const Color(0xFF1A2B47),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _firstNameController,
//                 decoration: const InputDecoration(labelText: 'First Name'),
//                 validator: (v) => v!.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _lastNameController,
//                 decoration: const InputDecoration(labelText: 'Last Name'),
//                 validator: (v) => v!.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 validator: (v) => v!.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: const InputDecoration(labelText: 'Phone'),
//                 validator: (v) => v!.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 controller: _amountController,
//                 decoration: const InputDecoration(labelText: 'Amount (₱)'),
//                 keyboardType: TextInputType.number,
//                 validator: (v) => v!.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _createPayment,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1A2B47),
//                   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Proceed to Pay', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }