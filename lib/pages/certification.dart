import 'package:flutter/material.dart';
import '../api_services.dart';

class MayorsPermitPage extends StatefulWidget {
  final String? applicationId;
  const MayorsPermitPage({super.key, this.applicationId});

  @override
  State<MayorsPermitPage> createState() => _MayorsPermitPageState();
}

class _MayorsPermitPageState extends State<MayorsPermitPage> {
  bool loading = true;
  Map<String, dynamic>? cert;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    if (widget.applicationId == null) {
      setState(() => loading = false);
      return;
    }

    final result = await ApiService.getCertificateDetails(widget.applicationId!);

    if (result["success"] == true) {
      setState(() {
        cert = result["data"];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (cert == null) {
      return const Scaffold(
        body: Center(child: Text("Certificate data not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('images/buguey(logo).jpg', width: 60),
                const SizedBox(width: 40, height: 40),
              ],
            ),
            const SizedBox(height: 4),

            const Text(
              'Republic of the Philippines\nProvince of Cagayan\nMUNICIPALITY OF BUGUEY',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            const Text(
              'OFFICE OF THE MAYOR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),

            const Text(
              "MAYOR'S PERMIT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // MAIN CONTENT WITH WATERMARK
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.1,
                  child: Image.asset('images/buguey(logo).jpg', width: 280),
                ),
                Column(
                  children: [
                    const Text('Taxpayer / Business Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(cert!['trade_name'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    const Text('Business Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(cert!['business_address'] ?? "—",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),

                    const Text('Permit/Certificate No.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(cert!['certificate_no'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),

                    const Text('Owner/Proprietor',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(cert!['owner'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'This is to certify that the above-named taxpayer/business has complied with all requirements and is hereby released from the custody of the Municipal Office for the purpose stated.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),

            // DATE LINE
            Text(
              cert!["date_paid"] ?? DateTime.now().toString(),
              style: const TextStyle(fontSize: 13),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('at Buguey, Cagayan, Philippines.',
                  style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 20),

            // SIGNATURE
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SizedBox(height: 30),
                  Text(
                    'LICERIO MILLARE ANTIPORDA III',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('Municipal Mayor', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FOOTER DETAILS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('O.R. Number: ', style: TextStyle(fontSize: 12)),
                  Text(cert!["or_number"] ?? "N/A"),
                ]),
                Row(children: [
                  const Text('Date of Issue: ', style: TextStyle(fontSize: 12)),
                  Text(cert!["date_paid"] ?? "-"),
                ]),
                Row(children: [
                  const Text('Amount Paid: PHP ', style: TextStyle(fontSize: 12)),
                  Text((cert!["amount_paid"] ?? 0.0).toString()),
                ]),
                Row(children: [
                  const Text('Date of Expiry: December 31, ', style: TextStyle(fontSize: 12)),
                  Text(DateTime.now().year.toString()),
                ]),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              'Note: This must bear the Original Signature of the Mayor',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "NO. 4754",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';

// class MayorsPermitPage extends StatelessWidget {
//   final String? applicationId;
//   const MayorsPermitPage({super.key, this.applicationId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // HEADER SECTION
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Image.asset(
//                   'images/buguey(logo).jpg',
//                   width: 60,
//                 ),
//                 SizedBox(
//                   width: 40,
//                   height: 40,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),

//             const Text(
//               'Republic of the Philippines\nProvince of Cagayan\nMUNICIPALITY OF BUGUEY',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//             ),
//             const SizedBox(height: 10),

//             const Text(
//               'OFFICE OF THE MAYOR',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//             ),
//             const SizedBox(height: 2),

//             const Text(
//               "MAYOR'S PERMIT",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             const SizedBox(height: 10),

//             // MAIN CONTENT WITH WATERMARK
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 Opacity(
//                   opacity: 0.1,
//                   child: Image.asset(
//                     'images/buguey(logo).jpg',
//                     width: 280,
//                   ),
//                 ),
//                 Column(
//                   children: const [
//                     Text('BUSINESS TRADE NAME', style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Text('KIND OF BUSINESS', style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Text('OWNER/PROPRIETOR', style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Text('LOCATION OF BUSINESS', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             const Text(
//               'PERMIT IS HEREBY GRANTED to the above-mentioned person to engage in the above-stated business after payment of the required License/Permit Fees and compliance with the ordinances, rules and regulations governing the business trade.',
//               textAlign: TextAlign.justify,
//               style: TextStyle(fontSize: 13, height: 1.4),
//             ),
//             const SizedBox(height: 12),

//             // DATE PLACEHOLDER
//             Row(
//               children: [
//                 const Text('GIVEN this ', style: TextStyle(fontSize: 13)),
//                 Container(width: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 1)))),
//                 const Text(' day of ', style: TextStyle(fontSize: 13)),
//                 Container(width: 70, decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 1)))),
//               ],
//             ),
//             const Align(
//               alignment: Alignment.centerLeft,
//               child: Text('at Buguey, Cagayan, Philippines.', style: TextStyle(fontSize: 13)),
//             ),
//             const SizedBox(height: 20),

//             // SIGNATURE
//             Align(
//               alignment: Alignment.centerRight,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: const [
//                   SizedBox(height: 30),
//                   Text(
//                     'LICERIO MILLARE ANTIPORDA III',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                   ),
//                   Text('Municipal Mayor', style: TextStyle(fontSize: 12)),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // FOOTER DETAILS
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(children: [
//                   const Text('O.R. Number:', style: TextStyle(fontSize: 12)),
//                   const SizedBox(width: 5),
//                   Container(width: 100, height: 14, color: Colors.white),
//                 ]),
//                 Row(children: [
//                   const Text('Date of Issue:', style: TextStyle(fontSize: 12)),
//                   const SizedBox(width: 5),
//                   Container(width: 100, height: 14, color: Colors.white),
//                 ]),
//                 Row(children: [
//                   const Text('Amount Paid:', style: TextStyle(fontSize: 12)),
//                   const SizedBox(width: 5),
//                   Container(width: 100, height: 14, color: Colors.white),
//                 ]),
//                 Row(children: [
//                   const Text('Date of Expiry:', style: TextStyle(fontSize: 12)),
//                   const SizedBox(width: 5),
//                   Container(width: 100, height: 14, color: Colors.white),
//                 ]),
//               ],
//             ),
//             const SizedBox(height: 8),

//             const Text(
//               'Note: This must bear the Original Signature of the Mayor',
//               style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
//             ),
//             const SizedBox(height: 6),

//             // CERTIFICATE NUMBER
//             Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 'No. 4754',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
