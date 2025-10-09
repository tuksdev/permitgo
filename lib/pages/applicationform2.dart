import 'package:flutter/material.dart';
import 'upload_documents.dart'; // Make sure the file name matches your actual file

class CheckmarkTable extends StatelessWidget {
  const CheckmarkTable({super.key});

  // Sample data
  final List<Map<String, dynamic>> data = const [
    {
      'Description': 'Occupancy Permit',
      'Office/Agency': 'Office of the Building Official',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'Barangay Clearance',
      'Office/Agency': 'Barangay',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'Sanitary/Health Clearance',
      'Office/Agency': 'Municipal Health Office',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'Municipal Environmental Certificate',
      'Office/Agency': 'Municipal Environment and Natural Resources Office',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'Market Clearance (For Stall Holders)',
      'Office/Agency': 'Office of the City/Municipal Market Administrator',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'Valid Fire Safety',
      'Office/Agency': 'Bureau of Fire Protection',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
    {
      'Description': 'DTI BN Certificate',
      'Office/Agency': 'DTI',
      'Yes': true,
      'No': false,
      'Not Needed': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Documents'),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Office/Agency',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Yes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Not Needed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: data.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['Description'])),
                      DataCell(Text(row['Office/Agency'])),
                      DataCell(row['Yes']
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox()),
                      DataCell(row['No']
                          ? const Icon(Icons.check, color: Colors.red)
                          : const SizedBox()),
                      DataCell(row['Not Needed']
                          ? const Icon(Icons.check, color: Colors.grey)
                          : const SizedBox()),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B47),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text(
                'Back to Form',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const UploadDocumentPage(applicationId: 'Business Permit'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B47),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
