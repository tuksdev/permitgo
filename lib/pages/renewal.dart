// import 'package:flutter/material.dart';
// import 'upload_documents.dart'; // <-- CORRECTED IMPORT NAME

// // NOTE: This screen MUST accept the Application ID (applicationId) 
// // of the new registration the user just created.
// class RegistrationDocumentsPage extends StatefulWidget {
//   final String applicationId; // <-- ADD THIS FIELD

//   const RegistrationDocumentsPage({super.key, required this.applicationId}); // <-- ADD REQUIRED FIELD

//   @override
//   State<RegistrationDocumentsPage> createState() =>
//       _RegistrationDocumentsPageState();
// }

// class _RegistrationDocumentsPageState extends State<RegistrationDocumentsPage> {
//   // Mapping of Display Name to Short Code (for the backend) and Upload Status
//   final Map<String, Map<String, dynamic>> documentMap = {
//     "Community Tax Certificate (Cedula)": {'code': 'CTC', 'uploaded': false},
//     "Barangay Clearance": {'code': 'BRGY_CLEARANCE', 'uploaded': false},
//     "DTI Certification / SEC": {'code': 'DTI_SEC', 'uploaded': false},
//     "Landholdings Certificate": {'code': 'LAND_CERT', 'uploaded': false},
//     "Fire Safety Inspection Certificate": {'code': 'FIRE_CERT', 'uploaded': false},
//     // ... add all other documents here with their short codes ...
//     "ITR or BIR Form 1701/1702 or 2550Q/2551Q": {'code': 'ITR', 'uploaded': false},
//   };

//   void markAsApproved(String docName) {
//     setState(() {
//       if (documentMap.containsKey(docName)) {
//         documentMap[docName]!['uploaded'] = true;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.blueGrey[900],
//         title: const Text(
//           'Registration Requirements',
//           style: TextStyle(fontSize: 18, color: Colors.white),
//         ),
//         leading: const BackButton(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF9F3FF),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: ListView(
//             children: documentMap.entries.map((entry) {
//               final docName = entry.key;
//               final docDetails = entry.value;
//               final docCode = docDetails['code'] as String; // e.g., 'CTC'
//               final approved = docDetails['uploaded'] as bool;
              
//               return ListTile(
//                 title: Text(
//                   docName,
//                   style: TextStyle(
//                     color: approved ? Colors.green[700] : Colors.black,
//                     decoration: approved ? TextDecoration.lineThrough : null,
//                   ),
//                 ),
//                 trailing: Icon(
//                   approved ? Icons.check_circle : Icons.upload_file,
//                   color: approved ? Colors.green[700] : Colors.grey,
//                   size: 24,
//                 ),
//                 onTap: () async {
//                   // Navigate to the upload screen, passing the ACTUAL Application ID
//                   // and the short CODE of the document being uploaded.
//                   final success = await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => UploadDocumentPage(
//                         applicationId: widget.applicationId, // <--- CORRECT ID
//                         documentName: docCode, // <--- CORRECT CODE
//                         businessName: docName, // Pass name for UI context
//                       ),
//                     ),
//                   );
                  
//                   // If the upload screen returns success, mark it as approved
//                   if (success == true) {
//                     markAsApproved(docName);
//                   }
//                 },
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }


// ==================================================================================================
// import 'package:flutter/material.dart';
// import 'upload_documents.dart';

// void main() => runApp(const MaterialApp(home: RegistrationDocumentsPage()));

// class RegistrationDocumentsPage extends StatefulWidget {
//   const RegistrationDocumentsPage({super.key});

//   @override
//   State<RegistrationDocumentsPage> createState() =>
//       _RegistrationDocumentsPageState();
// }

// class _RegistrationDocumentsPageState
//     extends State<RegistrationDocumentsPage> {
//   final Map<String, bool> documentStatus = {
//     "Community Tax Certificate (Cedula)": false,
//     "Barangay Clearance": false,
//     "Barangay Business Permit": false,
//     "DTI Certification / SEC": false,
//     "Landholdings Certificate": false,
//     "Fire Safety Inspection Certificate": false,
//     "Sanitary Permit/Health Certificate": false,
//     "MENRO Certificate": false,
//     "ITR or BIR Form 1701/1702 or 2550Q/2551Q": false,
//     // Optional
//     "MAFSO Certificate (If Fishing)": false,
//     "PNP Clearance (If Transport)": false,
//     "OR/CR (If Transport)": false,
//     "Transport Association's Certificate (If Transport)": false,
//     "Contract of Lease (If Lessee)": false,
//     "Lessor's Business Permit (If Lessee)": false,
//   };

//   void markAsApproved(String doc) {
//     setState(() {
//       documentStatus[doc] = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.blueGrey[900],
//         title: const Text(
//           'Business Registration Requirements',
//           style: TextStyle(fontSize: 18),
//         ),
//         leading: const BackButton(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF9F3FF),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: ListView(
//             children: documentStatus.entries.map((entry) {
//               final doc = entry.key;
//               final approved = entry.value;
//               return ListTile(
//                 title: Text(
//                   approved ? "$doc - Uploaded" : doc,
//                   style: TextStyle(
//                     color: approved ? Colors.green[700] : Colors.black,
//                     fontWeight:
//                         approved ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                 onTap: () async {
//                   final success = await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => UploadDocumentPage(applicationId: doc),
//                     ),
//                   );
//                   if (success == true) {
//                     markAsApproved(doc);
//                   }
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

