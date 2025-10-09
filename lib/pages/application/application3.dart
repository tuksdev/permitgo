// // import 'package:flutter/material.dart'
// import '../api_service.dart';

// class Application3FormScreen extends StatefulWidget {
//   final Map<String, dynamic> formData;
//   const Application3FormScreen({super.key, required this.formData});

//   @override
//   State<Application3FormScreen> createState() => _Application3FormScreenState();
// }

// class _Application3FormScreenState extends State<Application3FormScreen> {
//   final _lineOfBusiness = TextEditingController();
//   final _numOfUnits = TextEditingController();
//   final _capitalization = TextEditingController();
//   final _grossSalesEssential = TextEditingController();
//   final _grossSalesNonEssential = TextEditingController();

//   Future<void> _submitFinalForm() async {
//     final finalData = {
//       ...widget.formData,
//       "line_of_business": _lineOfBusiness.text,
//       "num_of_units": _numOfUnits.text,
//       "capitalization": _capitalization.text,
//       "gross_sales_essential": _grossSalesEssential.text,
//       "gross_sales_non_essential": _grossSalesNonEssential.text,
//     };

//     final result = await ApiService.submitNewApplication(finalData);

//     if (result["status"] == "success") {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Application submitted successfully!")),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${result["message"]}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Application Form - Page 3")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTextField("Line of Business", _lineOfBusiness),
//             _buildTextField("No. of Units", _numOfUnits),
//             _buildTextField("Capitalization", _capitalization),
//             _buildTextField("Gross Sales (Essential)", _grossSalesEssential),
//             _buildTextField("Gross Sales (Non-Essential)", _grossSalesNonEssential),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _submitFinalForm,
//               child: const Text("Submit All"),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
// }
