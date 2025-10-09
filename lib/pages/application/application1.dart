// import 'package:flutter/material.dart';
// import 'application2.dart';

// class ApplicationFormScreen extends StatefulWidget {
//   const ApplicationFormScreen({super.key});

//   @override
//   State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
// }

// class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
//   bool isNewApplication = false;
//   bool isRenewal = false;

//   bool isAnnually = false;
//   bool isSemiAnnually = false;
//   bool isQuarterly = false;

//   DateTime? selectedDate;

//   final _tinController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _firstNameController = TextEditingController();
//   final _middleNameController = TextEditingController();
//   final _businessNameController = TextEditingController();
//   final _accountNumberController = TextEditingController();
//   final _tradeNameController = TextEditingController();

//   void _submitForm() {
//     final formData = {
//       "application_type": isNewApplication ? "new" : "renewal",
//       "mode_of_payment": isAnnually
//           ? "Annually"
//           : isSemiAnnually
//               ? "Semi-Annually"
//               : "Quarterly",
//       "application_date": selectedDate?.toIso8601String() ?? "",
//       "tin_no": _tinController.text,
//       "last_name": _lastNameController.text,
//       "first_name": _firstNameController.text,
//       "middle_name": _middleNameController.text,
//       "business_name": _businessNameController.text,
//       "account_no": _accountNumberController.text,
//       "trade_name": _tradeNameController.text,
//     };

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Application2FormScreen(formData: formData),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Application Form - Page 1")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             CheckboxListTile(
//               title: const Text("New Application"),
//               value: isNewApplication,
//               onChanged: (val) {
//                 setState(() {
//                   isNewApplication = val!;
//                   isRenewal = !val;
//                 });
//               },
//             ),
//             CheckboxListTile(
//               title: const Text("Renewal"),
//               value: isRenewal,
//               onChanged: (val) {
//                 setState(() {
//                   isRenewal = val!;
//                   isNewApplication = !val;
//                 });
//               },
//             ),
//             const Divider(),
//             CheckboxListTile(
//               title: const Text("Annually"),
//               value: isAnnually,
//               onChanged: (val) {
//                 setState(() {
//                   isAnnually = val!;
//                   isSemiAnnually = false;
//                   isQuarterly = false;
//                 });
//               },
//             ),
//             CheckboxListTile(
//               title: const Text("Semi-Annually"),
//               value: isSemiAnnually,
//               onChanged: (val) {
//                 setState(() {
//                   isSemiAnnually = val!;
//                   isAnnually = false;
//                   isQuarterly = false;
//                 });
//               },
//             ),
//             CheckboxListTile(
//               title: const Text("Quarterly"),
//               value: isQuarterly,
//               onChanged: (val) {
//                 setState(() {
//                   isQuarterly = val!;
//                   isAnnually = false;
//                   isSemiAnnually = false;
//                 });
//               },
//             ),
//             const Divider(),
//             TextField(
//               controller: _tinController,
//               decoration: const InputDecoration(labelText: "TIN No"),
//             ),
//             TextField(
//               controller: _lastNameController,
//               decoration: const InputDecoration(labelText: "Last Name"),
//             ),
//             TextField(
//               controller: _firstNameController,
//               decoration: const InputDecoration(labelText: "First Name"),
//             ),
//             TextField(
//               controller: _middleNameController,
//               decoration: const InputDecoration(labelText: "Middle Name"),
//             ),
//             TextField(
//               controller: _businessNameController,
//               decoration: const InputDecoration(labelText: "Business Name"),
//             ),
//             TextField(
//               controller: _accountNumberController,
//               decoration: const InputDecoration(labelText: "Account No"),
//             ),
//             TextField(
//               controller: _tradeNameController,
//               decoration: const InputDecoration(labelText: "Trade Name"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _submitForm,
//               child: const Text("Next"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
