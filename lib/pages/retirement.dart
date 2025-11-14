import 'package:flutter/material.dart';
import 'upload_documents.dart'; // Assuming DocumentListScreen is here

void main() => runApp(const MaterialApp(home: RetirementDocumentsPage()));

class RetirementDocumentsPage extends StatefulWidget {
  const RetirementDocumentsPage({super.key});

  @override
  State<RetirementDocumentsPage> createState() => _RetirementDocumentsPageState();
}

class _RetirementDocumentsPageState extends State<RetirementDocumentsPage> {
  // 1. DEFINE the placeholder ID (int)
  final int retirementApplicationId = 12345; 

  final Map<String, bool> documentStatus = {
    "Original Business Permit": false,
    "Letter Request for Retirement": false,
    "Brgy. Certificate of Closure": false,
    "Picture of Closed Business": false,
    "Sketch of Place of Business": false,
  };

  void markAsUploaded(String doc) {
    setState(() {
      documentStatus[doc] = true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2. CREATE the String version of the ID for the navigation call
    final String retirementIdString = retirementApplicationId.toString(); 
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          'Retirement Of Business Registration',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView(
            children: [
              ...documentStatus.entries.map((entry) {
                final doc = entry.key;
                final uploaded = entry.value;

                return ListTile(
                  title: Text(
                    doc,
                    style: TextStyle(
                      color: uploaded ? Colors.green[700] : Colors.black,
                      fontWeight: uploaded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: uploaded
                      ? Icon(Icons.check_circle, color: Colors.green[700], size: 20)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    // 🛑 FINAL FIX: Call the correct list screen and pass all 3 required Strings 🛑
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentListScreen(
                            applicationId: retirementIdString, // Pass the String ID
                            businessName: 'Retirement Application', // Pass a name
                            documentPurpose: 'Retirement', // Pass the purpose tag
                            // The 'document' parameter is NOT needed here.
                        ),
                      ),
                    );
                    
                    if (success == true) {
                      markAsUploaded(doc);
                    }
                  },
                );
              }).toList(),
              
              const SizedBox(height: 20),
              // Final Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: documentStatus.values.every((uploaded) => uploaded)
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Retirement application submitted!')),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B47),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Submit Retirement', style: TextStyle(fontSize: 16, color: Colors.white)),
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
// // Assuming document_upload_screen.dart defines the UploadDocumentsScreen class
// import 'upload_documents.dart'; 
// // Also assuming UploadDocumentsScreen takes 'renewalId' which we'll call 'applicationId' for clarity

// void main() => runApp(const MaterialApp(home: RetirementDocumentsPage()));

// class RetirementDocumentsPage extends StatefulWidget {
//   const RetirementDocumentsPage({super.key});

//   @override
//   State<RetirementDocumentsPage> createState() => _RetirementDocumentsPageState();
// }

// class _RetirementDocumentsPageState extends State<RetirementDocumentsPage> {
//   // ⚠️ CRITICAL PLACEHOLDER: You must replace '12345' with the actual
//   // Application ID of the business being retired, retrieved from your server.
//   // For this fix, we use a placeholder ID.
//   final int retirementApplicationId = 12345; 

//   final Map<String, bool> documentStatus = {
//     "Original Business Permit": false,
//     "Letter Request for Retirement": false,
//     "Brgy. Certificate of Closure": false,
//     "Picture of Closed Business": false,
//     "Sketch of Place of Business": false,
//   };

//   void markAsUploaded(String doc) {
//     setState(() {
//       // Renamed to markAsUploaded for better clarity
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
//           'Retirement Of Business Registration',
//           style: TextStyle(fontSize: 18, color: Colors.white), // Added color for AppBar text
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
//             children: [
//               // Use ListTile to wrap the entire list for better spacing
//               ...documentStatus.entries.map((entry) {
//                 final doc = entry.key;
//                 final uploaded = entry.value;

//                 return ListTile(
//                   title: Text(
//                     // Use a simple Text widget structure for the title
//                     doc,
//                     style: TextStyle(
//                       color: uploaded ? Colors.green[700] : Colors.black,
//                       fontWeight: uploaded ? FontWeight.bold : FontWeight.normal,
//                     ),
//                   ),
//                   trailing: uploaded
//                       ? Icon(Icons.check_circle, color: Colors.green[700], size: 20)
//                       : const Icon(Icons.arrow_forward_ios, size: 16),
//                   onTap: () async {
//                     // 🛑 FIX: Use the correct, integer application ID 🛑
//                     // We assume UploadDocumentsScreen's parameter is named 'renewalId'
//                     final success = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => DocumentListScreen(
//                             applicationId: retirementApplicationIdString,
//                             businessName: 'Retirement Application',
//                             documentpurpose: 'Retirement',
//                             // Note: You might need to adjust UploadDocumentsScreen 
//                             // to handle retirement documents instead of renewal documents.
//                         ),
//                       ),
//                     );
                    
//                     if (success == true) {
//                       markAsUploaded(doc);
//                     }
//                   },
//                 );
//               }).toList(),
              
//               const SizedBox(height: 20),
//               // Final Submit Button
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: ElevatedButton(
//                   onPressed: documentStatus.values.every((uploaded) => uploaded)
//                       ? () {
//                           // Handle final submission logic here
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Retirement application submitted!')),
//                           );
//                         }
//                       : null, // Disable if not all documents are uploaded
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A2B47),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                   ),
//                   child: const Text('Submit Retirement', style: TextStyle(fontSize: 16, color: Colors.white)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }