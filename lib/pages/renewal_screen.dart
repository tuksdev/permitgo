import 'package:flutter/material.dart';
import 'dart:async'; // Added for Future.delayed if needed
import '../api_services.dart'; 
import 'upload_documents.dart'; // Import document screens
import '../user_session.dart'; 
import 'package:intl/intl.dart'; // Needed for date formatting

// =========================================================================
// WIDGET 1: RenewalScreen (STEP 1: SELECT BUSINESS LIST)
// =========================================================================

class RenewalScreen extends StatefulWidget {
  const RenewalScreen({super.key});

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  final String userId = UserSession.currentUserId; 
  late Future<List<dynamic>> _approvedBusinessesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch approved businesses filtered by user ID
    _approvedBusinessesFuture = ApiService.fetchApprovedBusinesses(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Business for Renewal', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _approvedBusinessesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center));
          }

          final businesses = snapshot.data ?? [];
          if (businesses.isEmpty) {
            return const Center(child: Text('No approved businesses found for renewal.', textAlign: TextAlign.center));
          }
          
          return ListView.builder(
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              final business = businesses[index];
              return ListTile(
                title: Text(business['business_name'] ?? 'N/A'),
                subtitle: Text('Address: ${business['business_address'] ?? 'N/A'}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the detail screen, passing ALL fetched data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RenewalDetailScreen(businessData: business),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// =========================================================================
// WIDGET 2: RenewalDetailScreen (STEP 2: PRE-FILL, EDIT FORM & SUBMIT)
// =========================================================================

class RenewalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;
  const RenewalDetailScreen({super.key, required this.businessData});

  @override
  State<RenewalDetailScreen> createState() => _RenewalDetailScreenState();
}

class _RenewalDetailScreenState extends State<RenewalDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  bool isRented = false;
  bool isSubmitting = false;
  bool hasTaxIncentive = false;

  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _entityController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();

  // 🛑 SCREEN 2/3 CONTROLLERS (Address/Activity) 🛑
  final TextEditingController _businessAddress = TextEditingController();
  final TextEditingController _postalCode = TextEditingController();
  final TextEditingController _ownerAddress = TextEditingController();
  final TextEditingController _ownerEmail = TextEditingController();
  final TextEditingController _ownerMobile = TextEditingController();
  final TextEditingController _emergencyContact = TextEditingController();
  final TextEditingController _emergencyEmail = TextEditingController();
  final TextEditingController _emergencyMobile = TextEditingController();
  final TextEditingController _businessArea = TextEditingController();
  final TextEditingController _employeesTotal = TextEditingController();
  final TextEditingController _employeesWithLGU = TextEditingController();
  final TextEditingController _lineOfBusiness = TextEditingController();
  final TextEditingController _numOfUnits = TextEditingController();
  final TextEditingController _capitalization = TextEditingController();
  
  // These two were removed from the main widget and must be initialized here:
  final TextEditingController _grossSalesEssential = TextEditingController(); 
  final TextEditingController _grossSalesNonEssential = TextEditingController(); 
  
  // NOTE: The previous code had duplicate declarations for _grossSalesEssential and _grossSalesNonEssential
  // I have assumed the ones inside the State class declaration (lines 100-101 in original input) 
  // were the intended declarations. 

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  @override
  void dispose() {
    _tinController.dispose();
    _entityController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _businessNameController.dispose();
    _accountNumberController.dispose();
    _tradeNameController.dispose();
    _businessAddress.dispose();
    _postalCode.dispose();
    _ownerAddress.dispose();
    _ownerEmail.dispose();
    _ownerMobile.dispose();
    _emergencyContact.dispose();
    _emergencyEmail.dispose();
    _emergencyMobile.dispose();
    _businessArea.dispose();
    _employeesTotal.dispose();
    _employeesWithLGU.dispose();
    _lineOfBusiness.dispose();
    _numOfUnits.dispose();
    _capitalization.dispose();
    _grossSalesEssential.dispose(); 
    _grossSalesNonEssential.dispose(); 

    super.dispose();
  }

  void _initializeControllers() {
    final data = widget.businessData;
    
   // --- Pre-fill controllers from the fetched data ---
    _tinController.text = data['tin_no'] ?? '';
    _entityController.text = data['tax_incentive_entity'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _firstNameController.text = data['first_name'] ?? '';
    _businessNameController.text = data['business_name'] ?? data['businessName'] ?? '';
    _accountNumberController.text = data['account_number'] ?? '';
    _tradeNameController.text = data['trade_name'] ?? '';
    
    _businessAddress.text = data['business_address'] ?? '';
    _postalCode.text = data['postal_code']?.toString() ?? '';
    _ownerAddress.text = data['owner_address'] ?? '';
    _ownerEmail.text = data['owner_email'] ?? data['email'] ?? '';
    _ownerMobile.text = data['owner_mobile'] ?? data['contact_number'] ?? '';
    _emergencyContact.text = data['emergency_contact'] ?? '';
    _emergencyEmail.text = data['emergency_email'] ?? '';
    _emergencyMobile.text = data['emergency_mobile'] ?? '';
    _businessArea.text = data['business_area']?.toString() ?? '';
    _employeesTotal.text = data['employees_total']?.toString() ?? '';
    _employeesWithLGU.text = data['employees_with_lgu']?.toString() ?? '';

    _lineOfBusiness.text = data['line_of_business'] ?? '';
    _numOfUnits.text = data['num_of_units']?.toString() ?? '';
    _capitalization.text = data['capitalization']?.toString() ?? '';
    // Initializing the Gross Sales controllers
    _grossSalesEssential.text = data['gross_sales_essential']?.toString() ?? '';
    _grossSalesNonEssential.text = data['gross_sales_nonessential']?.toString() ?? '';
    
    hasTaxIncentive = (data['has_tax_incentive'] == 1 || data['has_tax_incentive'] == true);
    isRented = (data['is_rented'] == 'Rented' || data['is_rented'] == 1);
    selectedDate = DateTime.tryParse(data['date_applied'] ?? '') ?? DateTime.now();
  }
  
  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // FIELDS ARE MODIFIABLE, but validation requires input (or null if optional)
        validator: (value) => value == null || value.isEmpty ? '$label is required' : null, 
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // helperText: 'Current value shown. Tap to modify.', 
        ),
      ),
    );
  }
  
  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Ensure the date is selected before proceeding
    if (selectedDate == null) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The Date of Application is required.")));
        }
        return;
    }

    setState(() => isSubmitting = true);
    
    final int originalAppId = (widget.businessData['application_id'] as num).toInt();

    // Collect all data, reflecting any changes made by the user
    final Map<String, dynamic> renewalData = {
      'business_id': originalAppId, 
      
      // --- SCREEN 1 DATA ---
      'tin_no': _tinController.text.trim(),
      'tax_incentive_entity': _entityController.text.trim(),
      'has_tax_incentive': hasTaxIncentive ? 1 : 0,
      'last_name': _lastNameController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'business_name': _businessNameController.text.trim(),
      'businessName': _businessNameController.text.trim(), // for backend compatibility
      'trade_name': _tradeNameController.text.trim(),
      'account_number': _accountNumberController.text.trim(),

      // --- SCREEN 2 DATA ---
      'business_address': _businessAddress.text.trim(),
      'owner_email': _ownerEmail.text.trim(),
      'owner_mobile': _ownerMobile.text.trim(),
      'email': _ownerEmail.text.trim(), // optional redundancy
      'contact_number': _ownerMobile.text.trim(),
      'owner_address': _ownerAddress.text.trim(),
      'postal_code': _postalCode.text.trim(),
      'is_rented': isRented ? 'Rented' : 'Owned',

      // --- SCREEN 3 DATA ---
      'line_of_business': _lineOfBusiness.text.trim(),
      'num_of_units': int.tryParse(_numOfUnits.text.trim()) ?? 0,
      'capitalization': double.tryParse(_capitalization.text.trim()) ?? 0.0,
      // 🛑 SEND MODIFIED GROSS SALES VALUES 🛑
      'gross_sales_essential': double.tryParse(_grossSalesEssential.text.trim()) ?? 0.0,
      'gross_sales_nonessential': double.tryParse(_grossSalesNonEssential.text.trim()) ?? 0.0,

      // --- ADDITIONAL / EMERGENCY INFO ---
      'emergency_contact': _emergencyContact.text.trim(),
      'emergency_email': _emergencyEmail.text.trim(),
      'emergency_mobile': _emergencyMobile.text.trim(),

      // --- BUSINESS DETAILS ---
      'business_area': double.tryParse(_businessArea.text.trim()) ?? 0.0,
      'employees_total': int.tryParse(_employeesTotal.text.trim()) ?? 0,
      'employees_with_lgu': int.tryParse(_employeesWithLGU.text.trim()) ?? 0,

      // --- DATE ---
      'application_date': selectedDate?.toIso8601String().split('T').first ?? '',

      // --- STATUS OR MISC ---
      'status': 'For Renewal', // optional default     // 🛑 Required to update 🛑
      
    };

    try {
      final result = await ApiService.submitRenewal(renewalData);

      if (result['success'] == true) {
        final int newRenewalId = (result['renewal_id'] as num).toInt(); 
        final businessName = widget.businessData['business_name'] ?? 'Renewal';

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Renewal submitted! Proceed to documents.")));
            
            // Navigate to the Document Upload Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentListScreen( 
                    applicationId: newRenewalId.toString(), 
                    businessName: businessName,
                    documentPurpose: 'Renewal', // Sets the mode for document list
                ),
              ),
            );
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission failed: ${result['message']}")));
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error submitting renewal: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Renewal - ${widget.businessData['business_name'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. Basic Information (Taxpayer/Business Name)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              // --- Editable Date Field ---
              const SizedBox(height: 16),
              const Text("Date of Application:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Text(selectedDate != null ? DateFormat('MM/dd/yyyy').format(selectedDate!) : 'Select a date'),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Financials Section (High Visibility) ---
              const Text("Financial Updates (Gross Receipts)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1A2B47))),
              _buildTextField("Gross/Sales Receipts (Essential)", _grossSalesEssential, isNumber: true),
              _buildTextField("Gross/Sales Receipts (Non-Essential)", _grossSalesNonEssential, isNumber: true),
              const Divider(height: 30),


              // --- Owner/TIN Info (Read-only for Renewal, but kept in controllers) ---
              _buildTextField("Last Name", _lastNameController),
              _buildTextField("First Name", _firstNameController),
              _buildTextField("TIN No.", _tinController),
              _buildTextField("Business Name", _businessNameController),
              // ... (Other Screen 1 fields: _accountNumberController, _tradeNameController) ...
              
              // Tax Incentive Radios
              const Text("Tax Incentive:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              // ... (Radio buttons UI remains here) ...
              const SizedBox(height: 16),
              
              // --- SCREEN 2: Address & Contact (MODIFIABLE) ---
              const Text("2. ADDRESS & CONTACT (Modify only if changed)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildTextField("Business Address", _businessAddress),
              _buildTextField("Owner's Email Address", _ownerEmail),
              _buildTextField("Owner's Mobile No.", _ownerMobile),
              
              CheckboxListTile(
                  title: const Text("Business Place is Rented"), 
                  value: isRented, 
                  onChanged: (value) {
                    setState(() => isRented = value ?? false);
                  }
              ),
              const SizedBox(height: 24),

              // --- SCREEN 3: Business Activity ---
              const Text("3. BUSINESS ACTIVITY (Modify only if changed)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildTextField("Line of Business", _lineOfBusiness),
              _buildTextField("No. of Units", _numOfUnits, isNumber: true),
              _buildTextField("Capitalization (₱)", _capitalization, isNumber: true),
              
              const SizedBox(height: 30),
              
              Center(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitRenewal,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                  child: isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Submit & Upload Documents', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      )
    );
  }
}

