import 'package:flutter/material.dart';
import 'upload_documents.dart';

void main() => runApp(const MaterialApp(home: RetirementDocumentsPage()));

class RetirementDocumentsPage extends StatefulWidget {
  const RetirementDocumentsPage({super.key});

  @override
  State<RetirementDocumentsPage> createState() => _RetirementDocumentsPageState();
}

class _RetirementDocumentsPageState extends State<RetirementDocumentsPage> {
  final Map<String, bool> documentStatus = {
    "Original Business Permit": false,
    "Letter Request for Retirement": false,
    "Brgy. Certificate of Closure": false,
    "Picture of Closed Business": false,
    "Sketch of Place of Business": false,
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
          'Retirement Of Business Registration',
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
                  approved ? "$doc - Approved" : doc,
                  style: TextStyle(
                    color: approved ? Colors.green[700] : Colors.black,
                    fontWeight: approved ? FontWeight.bold : FontWeight.normal,
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
