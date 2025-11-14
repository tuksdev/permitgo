// import 'package:flutter/material.dart';
// import 'dart:io'; 
// import 'package:file_picker/file_picker.dart';
// import '../api_services.dart'; // Adjust path as necessary
// import 'package:permitgo/models/document_model.dart'; // Import the model

// // --- List of Requirements Screen (Parent) ---
// class UploadDocumentsScreen extends StatefulWidget {
//   final int renewalId;

//   const UploadDocumentsScreen({super.key, required this.renewalId});

//   @override
//   State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
// }

// class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
//   // Initial document list (fixed list from the image)
//   List<DocumentRequirement> requiredDocuments = [
//     DocumentRequirement(documentName: 'Community Tax Certificate (Cedula)', documentCode: 'CTC'),
//     DocumentRequirement(documentName: 'Barangay Clearance', documentCode: 'BRGY_CLEARANCE'),
//     DocumentRequirement(documentName: 'Barangay Business Permit', documentCode: 'BRGY_PERMIT'),
//     DocumentRequirement(documentName: 'DTI Certification / SEC', documentCode: 'DTI_SEC'),
//     DocumentRequirement(documentName: 'Landholdings Certificate', documentCode: 'LANDHOLDINGS'),
//     DocumentRequirement(documentName: 'Fire Safety Inspection Certificate', documentCode: 'FIRE_SAFETY'),
//     DocumentRequirement(documentName: 'Sanitary Permit/Health Certificate', documentCode: 'SANITARY_HEALTH'),
//     DocumentRequirement(documentName: 'MENRO Certificate', documentCode: 'MENRO'),
//     DocumentRequirement(documentName: 'ITR or BIR Form 1701/1702 or 2550Q/2551Q', documentCode: 'ITR_BIR_FORM'),
//     DocumentRequirement(documentName: 'MAFSO Certificate (If Fishing)', documentCode: 'MAFSO'),
//     DocumentRequirement(documentName: 'PNP Clearance (If Transport)', documentCode: 'PNP'),
//   ];
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Business Registration Requirements')),
//       body: ListView.separated(
//         itemCount: requiredDocuments.length,
//         separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
//         itemBuilder: (context, index) {
//           final doc = requiredDocuments[index];
//           return ListTile(
//             title: Text(doc.documentName),
//             // UPLOAD INDICATOR LOGIC: Shows a checkmark if uploaded
//             trailing: doc.isUploaded 
//                 ? const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green, size: 20),
//                       SizedBox(width: 8),
//                       Icon(Icons.arrow_forward_ios, size: 16),
//                     ],
//                   )
//                 : const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () async {
//               // Navigate to the individual document upload screen
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => DocumentPickerScreen(
//                     renewalId: widget.renewalId,
//                     document: doc,
//                   ),
//                 ),
//               );
              
//               // 🛑 Update the status if the child screen signaled success (returned 'true') 🛑
//               if (result == true) {
//                 setState(() {
//                   doc.isUploaded = true;
//                 });
//               }
//             },
//           );
//         },
//       ),
//       // Floating button to complete submission
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: requiredDocuments.any((doc) => !doc.isUploaded) 
//             ? null // Disable if not all documents are uploaded
//             : () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('All documents uploaded. Proceeding...')),
//                 );
//                 // TODO: Navigate to Payment/Final Submission Screen
//             },
//         label: const Text('Complete Requirements'),
//         icon: const Icon(Icons.send),
//         backgroundColor: requiredDocuments.any((doc) => !doc.isUploaded) ? Colors.grey : Colors.blue,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }

// // -------------------------------------------------------------------
// // Individual Document Picker Screen (Child, handles upload)
// // -------------------------------------------------------------------

// class DocumentPickerScreen extends StatefulWidget {
//   final int renewalId;
//   final DocumentRequirement document;

//   const DocumentPickerScreen({
//     super.key, 
//     required this.renewalId, 
//     required this.document,
//   });

//   @override
//   State<DocumentPickerScreen> createState() => _DocumentPickerScreenState();
// }

// class _DocumentPickerScreenState extends State<DocumentPickerScreen> {
//   File? _selectedFile;
//   bool _isUploading = false;

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
//     );

//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//       });
//     }
//   }

//   Future<void> _uploadDocument() async {
//     if (_selectedFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a file first.')),
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       final response = await ApiService.uploadDocument(
//         applicationId: widget.renewalId.toString(),
//         documentName: widget.document.documentCode, // Send the unique CODE
//         file: _selectedFile!,
//       );

//       if (response['status'] == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${widget.document.documentName} uploaded!')),
//         );
//         // 🛑 CRITICAL: Pop and pass 'true' to signal success to the parent list screen 🛑
//         Navigator.pop(context, true); 
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Upload failed.')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upload Error: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.document.documentName)),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Requirement:',
//               style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
//             ),
//             Text(
//               widget.document.documentName,
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             // File Selection Button
//             ElevatedButton.icon(
//               onPressed: _isUploading ? null : _pickFile,
//               icon: const Icon(Icons.folder_open),
//               label: const Text('Select File'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Display Selected File Status
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 _selectedFile == null 
//                     ? 'No file selected. (PDF, JPG, PNG allowed)'
//                     : 'File Ready: ${_selectedFile!.path.split('/').last}',
//                 style: TextStyle(
//                   color: _selectedFile == null ? Colors.orange : Colors.green,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),

//             // Upload Button
//             ElevatedButton(
//               onPressed: (_selectedFile != null && !_isUploading) ? _uploadDocument : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//               ),
//               child: _isUploading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Upload & Save', style: TextStyle(fontSize: 18)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }