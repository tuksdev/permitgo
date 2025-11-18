// // lib/pages/released_certificates_list.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart';
import 'certification.dart'; // MayorsPermitPage

class ReleasedCertificatesList extends StatefulWidget {
  const ReleasedCertificatesList({super.key});

  @override
  State<ReleasedCertificatesList> createState() => _ReleasedCertificatesListState();
}

class _ReleasedCertificatesListState extends State<ReleasedCertificatesList> {
  bool _loading = true;
  List<dynamic> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? prefs.getInt("user_id")?.toString();

    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final res = await ApiService.getReleasedCertificates(userId);

    if (res["success"] == true) {
  setState(() {
    _certificates = res["certificates"] ?? [];   // ✅ Correct field
    _loading = false;
  });
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Released Certificates"),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? const Center(
                  child: Text("No released certificates found.",
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _certificates.length,
                  itemBuilder: (context, index) {
                    final item = _certificates[index];

                    final applicationId = item["application_id"];
                    final businessName =
                        item["business_name"] ?? item["trade_name"] ?? "Business";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0.5,
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(businessName,
                            style:
                                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text("Application ID: $applicationId"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MayorsPermitPage(
                                applicationId: applicationId.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_services.dart';
// import 'certification.dart';

// class ReleasedCertificatesList extends StatefulWidget {
//   const ReleasedCertificatesList({super.key});

//   @override
//   State<ReleasedCertificatesList> createState() => _ReleasedCertificatesListState();
// }

// class _ReleasedCertificatesListState extends State<ReleasedCertificatesList> {
//   bool _loading = true;
//   List<dynamic> _certificates = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadCertificates();
//   }

//   Future<void> _loadCertificates() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString("user_id");

//     if (userId == null) {
//       setState(() => _loading = false);
//       return;
//     }

//     final response = await ApiService.getReleasedCertificates(userId);

//     if (response["success"] == true) {
//       setState(() {
//         _certificates = response["data"];
//         _loading = false;
//       });
//     } else {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Released Certificates"),
//         backgroundColor: const Color(0xFF1A2B47),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _certificates.isEmpty
//               ? const Center(child: Text("No released certificates yet"))
//               : ListView.builder(
//                   itemCount: _certificates.length,
//                   itemBuilder: (context, index) {
//                     final cert = _certificates[index];

//                     return Card(
//                       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       child: ListTile(
//                         leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
//                         title: Text(cert["business_name"] ?? "Business"),
//                         subtitle: Text("Issued: ${cert["date_issued"]}"),
//                         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => MayorsPermitPage(
//                                 applicationId: cert["application_id"].toString(),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }
