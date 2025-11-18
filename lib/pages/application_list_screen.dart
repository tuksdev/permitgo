// lib/pages/applications_list_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart';
import 'upload_documents.dart';
import 'application.dart';


class ApplicationsListScreen extends StatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  State<ApplicationsListScreen> createState() =>
      _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends State<ApplicationsListScreen> {
  bool loading = true;
  List<dynamic> applications = [];

  @override
  void initState() {
    super.initState();
    fetchPendingApplications();
  }

  Future<void> fetchPendingApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final result = await ApiService.getPendingApplications(userId);
      setState(() {
        applications = result;
        loading = false;
      });
    } catch (e) {
      print("Error fetching pending applications: $e");
      setState(() => loading = false);
    }
  }

  // Determine documentPurpose
  String getDocumentPurpose(dynamic app) {
    final type = (app['application_type'] ?? "").toString().toLowerCase();
    final status = (app['status'] ?? "").toString().toLowerCase();

    if (type == "renewal") return "Renewal";
    if (type == "retirement") return "Retirement";

    // fallback using status
    if (status.contains("renewal")) return "Renewal";
    return "Registration";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Applications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟦 NEW Application Button at Top
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("New Application"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2B47),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApplicationFormScreen(),
                        ),
                      );
                    },
                  ),
                ),

                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Pending Applications",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Pending Applications List
                Expanded(
                  child: applications.isEmpty
                      ? const Center(
                          child: Text(
                            "No pending applications.\nCreate a new one!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: applications.length,
                          itemBuilder: (context, index) {
                            final app = applications[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(Icons.pending_actions,
                                    color: Colors.orange),
                                title: Text(
                                  app['business_name'] ??
                                      "Unnamed Business Application",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text("Type: ${app['application_type']}"),
                                    Text("Status: ${app['status']}"),
                                    Text("Date: ${app['application_date']}"),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),

                                // 📌 On TAP → go to upload documents
                                onTap: () {
                                  final purpose =
                                      getDocumentPurpose(app); // FIXED

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocumentListScreen(
                                        applicationId: app['application_id']
                                            .toString(),
                                        businessName:
                                            app['business_name'] ?? "Business",
                                        documentPurpose: purpose,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
