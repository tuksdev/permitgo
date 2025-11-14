// // lib/pages/upload_document_page.dart

// import 'package:flutter/material.dart';
// import 'dart:io'; 
// import 'package:file_picker/file_picker.dart';
// import '../api_services.dart'; 

// // ====================================================================
// // MODEL: DocumentType 
// // This model is used internally by this widget to manage file state.
// // ====================================================================
// class DocumentType {
//   final String code; // Unique code sent to backend (e.g., 'CTC')
//   final String name; 
//   File? file;
//   bool isUploaded; 

//   DocumentType({required this.code, required this.name, this.file, this.isUploaded = false});
// }

// // ====================================================================
// // WIDGET: UploadDocumentPage (The Main Screen)
// // ====================================================================
// class UploadDocumentPage extends StatefulWidget {
//   final String applicationId; // Received from successful submission
//   final String businessName; // Received for display purposes

//   const UploadDocumentPage({
//     super.key, 
//     required this.applicationId,
//     required this.businessName,
//   });

//   @override
//   State<UploadDocumentPage> createState() => _UploadDocumentPageState();
// }

// class _UploadDocumentPageState extends State<UploadDocumentPage> {
  
//   // 🛑 UPDATED LIST FOR NEW REGISTRATION 🛑
//   final List<DocumentType> _requiredDocuments = [
//     DocumentType(code: 'CTC', name: '1. Community Tax Certificate (Cedula)'),
//     DocumentType(code: 'BRGY_CLEARANCE', name: '2. Barangay Clearance'),
//     DocumentType(code: 'BRGY_PERMIT', name: '3. Barangay Business Permit'),
//     DocumentType(code: 'DTI_SEC', name: '4. DTI Certification / SEC for business establishments'),
//     DocumentType(code: 'LANDHOLDINGS', name: '5. Landholdings certificate'),
//     DocumentType(code: 'SANITARY_HEALTH', name: '6. Sanitary Permit/Health Certificate'),
//     DocumentType(code: 'MENRO', name: '7. MENRO Certificate'),
//     DocumentType(code: 'FIRE_SAFETY', name: '8. Fire Safety Inspection Certificate'),
//     DocumentType(code: 'SEPD', name: '9. SEPD certification'),
//   ];
  
//   DocumentType? _selectedDocumentType;
//   bool _isUploading = false;

//   // --- Utility: Check if all required documents have been uploaded ---
//   bool get _isAllUploaded => _requiredDocuments.every((doc) => doc.isUploaded);

//   // --- File Picker and Upload Logic (Retained from previous steps) ---
  
//   Future<void> _pickFile(DocumentType docType) async {
//     if (docType.isUploaded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('${docType.name} is already uploaded. Selecting a new file will replace it.')),
//       );
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
//       // API call to the backend. Pass "Registration" as the document purpose.
//       final response = await ApiService.uploadDocument(
//         applicationId: widget.applicationId, 
//         documentName: docToUpload.code,      
//         file: docToUpload.file!,
//         documentPurpose: 'Registration', // 🛑 NEW APPLICATION = REGISTRATION 🛑
//       );

//       if (!mounted) return; 

//       if (response['status'] == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${docToUpload.name} uploaded successfully!')),
//         );
//         setState(() {
//             _selectedDocumentType!.isUploaded = true; 
//             _selectedDocumentType!.file = null;     
//             _selectedDocumentType = null;          
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

//   // --- Finalize Registration ---
//   void _finalizeRegistration() {
//     // This is the final step after all documents are uploaded.
//     ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('All documents submitted. Application sent for final review!')),
//     );
    
//     // Navigate back to the Home/Dashboard, clearing the navigation stack
//     Navigator.popUntil(context, (route) => route.isFirst); 
//   }

//   // --- UI Build ---
//   @override
//   Widget build(BuildContext context) {
//     final bool isSelectedFileReady = _selectedDocumentType != null && _selectedDocumentType!.file != null;
    
//     return Scaffold(
//       appBar: AppBar(
//           title: Text('Registration Documents: ${widget.businessName}', style: const TextStyle(color: Colors.white)),
//           backgroundColor: const Color(0xFF1A2B47)),
      
//       // Floating button visible only when all documents are uploaded
//       floatingActionButton: _isAllUploaded ? FloatingActionButton.extended(
//         onPressed: _finalizeRegistration,
//         label: const Text('Finalize Submission', style: TextStyle(fontSize: 16)),
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
                
//                 final bool isSelected = _selectedDocumentType?.code == doc.code && doc.file != null;

//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   elevation: isSelected ? 3 : 1,
//                   color: isSelected ? Colors.lightBlue.shade50 : null,
//                   child: ListTile(
//                     leading: Icon(
//                       doc.isUploaded ? Icons.check_circle : Icons.upload_file,
//                       color: doc.isUploaded ? Colors.green : (isSelected ? Colors.blue : Colors.orange),
//                     ),
//                     title: Text(doc.name, style: TextStyle(fontWeight: doc.isUploaded ? FontWeight.bold : FontWeight.w500)),
//                     subtitle: Text(
//                       doc.isUploaded
//                           ? 'Status: UPLOADED.'
//                           : doc.file != null 
//                               ? 'Ready: ${doc.file!.path.split('/').last}'
//                               : 'Tap here to pick file',
//                       style: TextStyle(
//                         color: doc.isUploaded ? Colors.green.shade700 : (isSelected ? Colors.blue : Colors.grey),
//                       ),
//                     ),
//                     trailing: doc.isUploaded ? const SizedBox.shrink() : const Icon(Icons.attachment),
//                     onTap: () => _pickFile(doc),
//                   ),
//                 );
//               },
//             ),
//           ),
          
//           // --- UPLOAD BUTTON SECTION ---
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: (isSelectedFileReady && !_isUploading) ? _uploadDocument : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelectedFileReady ? Colors.blue : Colors.grey,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: _isUploading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : Text(
//                       isSelectedFileReady
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