// import 'package:flutter/material.dart';
// import 'application3.dart';
// import '../../api_service.dart';

// class Application2FormScreen extends StatefulWidget {
//   final Map<String, dynamic> formData;
//   const Application2FormScreen({super.key, required this.formData});

//   @override
//   State<Application2FormScreen> createState() => _Application2FormScreenState();
// }

// class _Application2FormScreenState extends State<Application2FormScreen> {
//   final _businessAddress = TextEditingController();
//   final _postalCode = TextEditingController();
//   final _ownerAddress = TextEditingController();
//   final _ownerEmail = TextEditingController();
//   final _ownerMobile = TextEditingController();
//   final _emergencyContact = TextEditingController();
//   final _emergencyEmail = TextEditingController();
//   final _emergencyMobile = TextEditingController();
//   final _businessArea = TextEditingController();
//   final _employeesTotal = TextEditingController();
//   final _employeesWithLGU = TextEditingController();

//   bool isRented = false;
//   final _lessorName = TextEditingController();
//   final _lessorAddress = TextEditingController();
//   final _lessorContact = TextEditingController();
//   final _lessorEmail = TextEditingController();
//   final _monthlyRental = TextEditingController();

//   void _goNext() {
//     final updatedData = {
//       ...widget.formData,
//       "business_address": _businessAddress.text,
//       "postal_code": _postalCode.text,
//       "owner_address": _ownerAddress.text,
//       "owner_email": _ownerEmail.text,
//       "owner_mobile": _ownerMobile.text,
//       "emergency_contact": _emergencyContact.text,
//       "emergency_email": _emergencyEmail.text,
//       "emergency_mobile": _emergencyMobile.text,
//       "business_area": _businessArea.text,
//       "employees_total": _employeesTotal.text,
//       "employees_with_lgu": _employeesWithLGU.text,
//       "is_rented": isRented ? "Yes" : "No",
//       "lessor_name": _lessorName.text,
//       "lessor_address": _lessorAddress.text,
//       "lessor_contact": _lessorContact.text,
//       "lessor_email": _lessorEmail.text,
//       "monthly_rental": _monthlyRental.text,
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Application3FormScreen(formData: updatedData),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Application Form - Page 2")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(controller: _businessAddress, decoration: const InputDecoration(labelText: "Business Address")),
//             TextField(controller: _postalCode, decoration: const InputDecoration(labelText: "Postal Code")),
//             TextField(controller: _ownerAddress, decoration: const InputDecoration(labelText: "Owner Address")),
//             TextField(controller: _ownerEmail, decoration: const InputDecoration(labelText: "Owner Email")),
//             TextField(controller: _ownerMobile, decoration: const InputDecoration(labelText: "Owner Mobile")),
//             TextField(controller: _emergencyContact, decoration: const InputDecoration(labelText: "Emergency Contact")),
//             TextField(controller: _emergencyEmail, decoration: const InputDecoration(labelText: "Emergency Email")),
//             TextField(controller: _emergencyMobile, decoration: const InputDecoration(labelText: "Emergency Mobile")),
//             TextField(controller: _businessArea, decoration: const InputDecoration(labelText: "Business Area")),
//             TextField(controller: _employeesTotal, decoration: const InputDecoration(labelText: "Employees Total")),
//             TextField(controller: _employeesWithLGU, decoration: const InputDecoration(labelText: "Employees with LGU")),
//             CheckboxListTile(
//               title: const Text("Is Rented?"),
//               value: isRented,
//               onChanged: (val) => setState(() => isRented = val!),
//             ),
//             if (isRented) ...[
//               TextField(controller: _lessorName, decoration: const InputDecoration(labelText: "Lessor Name")),
//               TextField(controller: _lessorAddress, decoration: const InputDecoration(labelText: "Lessor Address")),
//               TextField(controller: _lessorContact, decoration: const InputDecoration(labelText: "Lessor Contact")),
//               TextField(controller: _lessorEmail, decoration: const InputDecoration(labelText: "Lessor Email")),
//               TextField(controller: _monthlyRental, decoration: const InputDecoration(labelText: "Monthly Rental")),
//             ],
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _goNext,
//               child: const Text("Next"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
