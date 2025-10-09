import 'package:flutter/material.dart';
import 'upload_documents.dart';

void main() => runApp(const MaterialApp(home: RegistrationDocumentsPage()));

class RegistrationDocumentsPage extends StatefulWidget {
  const RegistrationDocumentsPage({super.key});

  @override
  State<RegistrationDocumentsPage> createState() =>
      _RegistrationDocumentsPageState();
}

class _RegistrationDocumentsPageState
    extends State<RegistrationDocumentsPage> {
  final Map<String, bool> documentStatus = {
    "Community Tax Certificate (Cedula)": false,
    "Barangay Clearance": false,
    "Barangay Business Permit": false,
    "DTI Certification / SEC": false,
    "Landholdings Certificate": false,
    "Fire Safety Inspection Certificate": false,
    "Sanitary Permit/Health Certificate": false,
    "MENRO Certificate": false,
    "ITR or BIR Form 1701/1702 or 2550Q/2551Q": false,
    // Optional
    "MAFSO Certificate (If Fishing)": false,
    "PNP Clearance (If Transport)": false,
    "OR/CR (If Transport)": false,
    "Transport Association's Certificate (If Transport)": false,
    "Contract of Lease (If Lessee)": false,
    "Lessor's Business Permit (If Lessee)": false,
  };

  void markAsApproved(String doc) {
    setState(() {
      documentStatus[doc] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          'Business Registration Requirements',
          style: TextStyle(fontSize: 18),
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
            children: documentStatus.entries.map((entry) {
              final doc = entry.key;
              final approved = entry.value;
              return ListTile(
                title: Text(
                  approved ? "$doc - Uploaded" : doc,
                  style: TextStyle(
                    color: approved ? Colors.green[700] : Colors.black,
                    fontWeight:
                        approved ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final success = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadDocumentPage(applicationId: doc),
                    ),
                  );
                  if (success == true) {
                    markAsApproved(doc);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

