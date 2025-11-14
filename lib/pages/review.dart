// lib/pages/review.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services.dart'; 
import 'upload_documents.dart'; // Assumed: Contains DocumentListScreen

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> finalData;
  const ReviewScreen({super.key, required this.finalData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _isSubmitting = false;

  // 🛑 FIX: This function is now correctly used inside the build method 🛑
  Widget _buildDetailTile(String title, dynamic value) {
    final displayValue = value == null || value.toString().trim().isEmpty || value.toString() == '0'
        ? 'N/A' 
        : value.toString();
        
          return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }

  // --- Final Submission Logic ---
  Future<void> _submitAndNavigateToUpload() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    // --- 1. Get User ID ---
    final prefs = await SharedPreferences.getInstance();
    String? userIdStr = prefs.getString('user_id');
    if (userIdStr == null) {
      final userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) userIdStr = userIdInt.toString();
    }
    if (userIdStr == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: User session lost. Please log in.")));
      setState(() => _isSubmitting = false);
      return;
    }

    // --- 2. Prepare Payload ---
    final Map<String, dynamic> payload = {
      "user_id": userIdStr,
      ...widget.finalData,
    };

    try {
      // 3. Call API to Submit Application (Returns application_id)
      final result = await ApiService.submitApplication(payload);

      if (mounted) {
        if (result["status"] == "success") {
          final newApplicationId = result["application_id"]?.toString();
          final businessName = payload['businessName'] ?? 'New Business';
          
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Submitted! Proceeding to documents.")));
          
          // 4. Navigate to Document List Screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentListScreen( // Correct Class Name
                applicationId: newApplicationId!, 
                businessName: businessName,
                documentPurpose: 'Registration', // Sets the purpose for document list
              ),
            ),
            (route) => route.isFirst, // Back to Dashboard
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission failed: ${result["message"] ?? 'Server failed to process.'}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("API Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.finalData;

    final isRentedStatus = data['is_rented'] == 1 ? 'Yes' : 'No';
    final hasTaxIncentiveStatus = data['has_tax_incentive'] == 1 ? 'Yes' : 'No';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Application', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button to Screen 3 (Activity)
                TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("← Back to Edit Forms"),
                ),
                const Divider(height: 10, thickness: 1),
                
                const Text("1. Basic Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0, color: Color(0xFF1A2B47))),
                const SizedBox(height: 8),

                _buildDetailTile("Taxpayer Name", "${data['first_name']} ${data['middle_name'] ?? ''} ${data['last_name']}"),
                _buildDetailTile("Business Name", data['businessName']),
                _buildDetailTile("Trade Name/Franchise", data['trade_name']),
                _buildDetailTile("Account No.", data['account_number']),
                _buildDetailTile("TIN No.", data['tin_no']),
                _buildDetailTile("Application Type", data['application_type']),
                _buildDetailTile("Mode of Payment", data['mode_of_payment']),
                _buildDetailTile("Business Type", data['business_type']),
                _buildDetailTile("Tax Incentive", hasTaxIncentiveStatus),
                if (data['has_tax_incentive'] == 1)
                    _buildDetailTile("Entity Specified", data['tax_incentive_entity']),
                _buildDetailTile("Amendment From", data['amendment_from']),
                _buildDetailTile("Amendment To", data['amendment_to']),
                const Divider(height: 24, thickness: 1),

                const Text("2. Other Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0, color: Color(0xFF1A2B47))),
                const SizedBox(height: 8),

                _buildDetailTile("Business Address", data['business_address']),
                _buildDetailTile("Postal Code", data['postal_code']),
                _buildDetailTile("Owner's Address", data['owner_address']),
                _buildDetailTile("Owner Email", data['owner_email']),
                _buildDetailTile("Owner Mobile", data['owner_mobile']),
                _buildDetailTile("Business Area (sq m)", data['business_area']),
                _buildDetailTile("Total Employees", data['employees_total']),
                _buildDetailTile("Employees w/ LGU", data['employees_with_lgu']),
                _buildDetailTile("Emergency Contact", data['emergency_contact']),
                _buildDetailTile("Emergency Mobile", data['emergency_mobile']),
                
                _buildDetailTile("Place Rented", isRentedStatus),
                // --- LESSOR DETAILS (Conditional) ---
                if (data['is_rented'] == 1) ...[
                    _buildDetailTile("Lessor Name", data['lessor_name']),
                    _buildDetailTile("Monthly Rent", "₱ ${data['monthly_rent']}"),
                ],
                const Divider(height: 24, thickness: 1),

                const Text("3. Business Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0, color: Color(0xFF1A2B47))),
                const SizedBox(height: 8),

                _buildDetailTile("Line of Business", data['line_of_business']),
                _buildDetailTile("No. of Units", data['num_of_units']),
                _buildDetailTile("Capitalization", "₱ ${data['capitalization']}"),
                _buildDetailTile("Gross Sales (Essential)", "₱ ${data['gross_sales_essential']}"),
                _buildDetailTile("Gross Sales (Non-Essential)", "₱ ${data['gross_sales_non_essential']}"),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          // --- FINAL SUBMIT BUTTON (Sticky) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAndNavigateToUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('CONFIRM & UPLOAD DOCUMENTS', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}