

// // lib/pages/upload_document_page.dart

// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import '../api_services.dart';

// // Model to represent a document type (kept for reference)
// class DocumentType {
//   final String code; // e.g., 'CTC', 'BRGY_CLEARANCE' (sent to backend)
//   final String name; 
//   File? file;
//   bool isUploaded; // <-- NEW: Tracks permanent upload status

//   DocumentType({required this.code, required this.name, this.file, this.isUploaded = false});
// }

// class UploadDocumentPage extends StatefulWidget {
//   final String applicationId;
//   final String businessName;

//   const UploadDocumentPage({
//     super.key, 
//     required this.applicationId,
//     required this.businessName,
//   });

//   @override
//   State<UploadDocumentPage> createState() => _UploadDocumentPageState();
// }

// class _UploadDocumentPageState extends State<UploadDocumentPage> {
//   // Define the list of required documents for renewal.
//   // NOTE: Use 'isUploaded' to track success, not just 'file'.
//   final List<DocumentType> _requiredDocuments = [
//     DocumentType(code: 'CTC', name: '1. Community Tax Certificate (CTC)'),
//     DocumentType(code: 'BRGY_CLEARANCE', name: '2. Barangay Business Clearance'),
//     DocumentType(code: 'FIRE_PERMIT', name: '3. Fire Safety Inspection Cert.'),
//     DocumentType(code: 'SANITARY_PERMIT', name: '4. Sanitary Permit'),
//   ];
  
//   DocumentType? _selectedDocumentType;
//   bool _isUploading = false;

//   // --- Utility: Check if all required documents have been uploaded ---
//   bool get _isAllUploaded => _requiredDocuments.every((doc) => doc.isUploaded);

//   // --- File Picker ---
//   Future<void> _pickFile(DocumentType docType) async {
//     // Check if the document has already been permanently uploaded (optional check)
//     if (docType.isUploaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('${docType.name} is already uploaded.')),
//       );
//       return;
//     }

//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
//     );

//     if (result != null && result.files.single.path != null) {
//       final index = _requiredDocuments.indexWhere((doc) => doc.code == docType.code);
      
//       if (!mounted) return; 

//       setState(() {
//         _requiredDocuments[index].file = File(result.files.single.path!);
//         _selectedDocumentType = _requiredDocuments[index]; 
//       });
//     }
//   }

//   // --- Upload Logic ---
//   Future<void> _uploadDocument() async {
//     final docToUpload = _selectedDocumentType;

//     if (docToUpload == null || docToUpload.file == null) {
//       if (!mounted) return; 
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error: Please select a file to upload.')),
//       );
//       return;
//     }

//     if (!mounted) return; 
//     setState(() => _isUploading = true);

//     try {
//       final response = await ApiService.uploadDocument(
//         applicationId: widget.applicationId,
//         documentName: docToUpload.code, 
//         file: docToUpload.file!,
//       );

//       if (!mounted) return; 

//       if (response['status'] == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${docToUpload.name} uploaded successfully!')),
//         );
//         // Mark the original document item as permanently uploaded
//         setState(() {
//             _selectedDocumentType!.isUploaded = true; // Permanent checkmark
//             _selectedDocumentType!.file = null;     // Clear temporary file object
//             _selectedDocumentType = null;          // Clear selection
//         });
        
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Upload failed.')),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upload Error: ${e.toString()}')),
//       );
//     } finally {
//       if (!mounted) return;
//       setState(() => _isUploading = false);
//     }
//   }

//   // --- Finalize Renewal ---
//   void _finalizeRenewal() {
//     // TODO: This is where you would call the final backend endpoint (e.g., /api/applications/finalize_renewal)
//     // to change the application status from 'Pending Documents' to 'Pending Review'.
    
//     // For now, we simulate success and navigate the user back to the list.
//     ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('All documents submitted. Renewal application sent for review!')),
//     );
    
//     // Navigate back, potentially causing the RenewalScreen list to refresh
//     Navigator.pop(context, true); 
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title: Text('Renewal: ${widget.businessName}'),
//           backgroundColor: const Color(0xFF1A2B47)),
      
//       // Floating button visible only when all documents are uploaded
//       floatingActionButton: _isAllUploaded ? FloatingActionButton.extended(
//         onPressed: _finalizeRenewal,
//         label: const Text('Finalize Renewal', style: TextStyle(fontSize: 16)),
//         icon: const Icon(Icons.send),
//         backgroundColor: Colors.green,
//       ) : null,
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               'Upload required documents for Application ID: ${widget.applicationId}',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _isAllUploaded ? Colors.green : Colors.black),
//             ),
//           ),
          
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               itemCount: _requiredDocuments.length,
//               itemBuilder: (context, index) {
//                 final doc = _requiredDocuments[index];
                
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   elevation: 1,
//                   child: ListTile(
//                     leading: Icon(
//                       doc.isUploaded ? Icons.check_circle : Icons.upload_file,
//                       color: doc.isUploaded ? Colors.green : Colors.orange,
//                     ),
//                     title: Text(doc.name, style: TextStyle(fontWeight: doc.isUploaded ? FontWeight.bold : FontWeight.w500)),
//                     subtitle: Text(
//                       doc.isUploaded
//                           ? 'Status: UPLOADED. Awaiting review.'
//                           : doc.file != null 
//                               ? 'Ready to upload: ${doc.file!.path.split('/').last}'
//                               : 'Tap here to pick file',
//                       style: TextStyle(
//                         color: doc.isUploaded ? Colors.green.shade700 : Colors.grey,
//                       ),
//                     ),
//                     trailing: doc.isUploaded ? const SizedBox.shrink() : const Icon(Icons.attachment),
//                     onTap: () => _pickFile(doc),
//                   ),
//                 );
//               },
//             ),
//           ),
          
//           // --- UPLOAD BUTTON SECTION (For the currently selected file) ---
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               // Button is enabled only if a file is ready AND we are not currently uploading
//               onPressed: (_selectedDocumentType?.file != null && !_isUploading) ? _uploadDocument : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: _isUploading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : Text(
//                       _selectedDocumentType != null && _selectedDocumentType!.file != null
//                           ? 'Upload ${_selectedDocumentType!.name}' 
//                           : 'Select a Document to Upload', 
//                       style: const TextStyle(fontSize: 18)
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ///////////////////////////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import '../api_service.dart';
// import 'package:permitgo/models/document_model.dart';

// class UploadDocumentPage extends StatefulWidget {
//   final String applicationId;

//   const UploadDocumentPage({super.key, required this.applicationId});

//   @override
//   State<UploadDocumentPage> createState() => _UploadDocumentPageState();
// }

// class _UploadDocumentPageState extends State<UploadDocumentPage> {
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
//         applicationId: widget.applicationId,
//         documentName: 'CTC', // Default or pass from parent
//         file: _selectedFile!,
//       );

//       if (response['status'] == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Document uploaded successfully!')),
//         );
//         Navigator.pop(context, true); // Return success
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
//       appBar: AppBar(title: const Text('Upload Document')),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'Upload Document',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             ElevatedButton.icon(
//               onPressed: _isUploading ? null : _pickFile,
//               icon: const Icon(Icons.folder_open),
//               label: const Text('Select File'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//               ),
//             ),
//             const SizedBox(height: 20),

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
