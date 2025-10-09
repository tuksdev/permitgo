// application.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

//
// Screen 1 = ApplicationFormScreen
// Screen 2 = Application2FormScreen
// Screen 3 = Application3FormScreen (final submit)
//

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  bool isNewApplication = false;
  bool isRenewal = false;

  bool isAnnually = false;
  bool isSemiAnnually = false;
  bool isQuarterly = false;

  bool isSingle = false;
  bool isPartnership = false;
  bool isCorporation = false;
  bool isCooperative = false;

  bool isFromSingle = false;
  bool isFromPartnership = false;
  bool isFromCorporation = false;

  bool isToSingle = false;
  bool isToPartnership = false;
  bool isToCorporation = false;

  bool? hasTaxIncentive = false;

  DateTime? selectedDate;

  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _entityController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();

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
    super.dispose();
  }

  void _goToNext() {
    // build partial data map from screen 1
    final Map<String, dynamic> data = {
      // top-level keys your backend currently expects for taxpayer + application
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "middle_name": _middleNameController.text.trim(),
      "trade_name": _tradeNameController.text.trim(),
      "businessName": _businessNameController.text.trim(),
      "account_number": _accountNumberController.text.trim(),
      "tin_no": _tinController.text.trim(),
      // application_type, mode_of_payment, business_type, amendment_from/ to
      "application_type": isNewApplication ? "New Application" : (isRenewal ? "Renewal" : ""),
      "mode_of_payment": isAnnually ? "Annually" : (isSemiAnnually ? "Semi-Annually" : (isQuarterly ? "Quarterly" : "")),
      "business_type": isSingle ? "Single" : (isPartnership ? "Partnership" : (isCorporation ? "Corporation" : (isCooperative ? "Cooperative" : ""))),
      "amendment_from": isFromSingle ? "Single" : (isFromPartnership ? "Partnership" : (isFromCorporation ? "Corporation" : "")),
      "amendment_to": isToSingle ? "Single" : (isToPartnership ? "Partnership" : (isToCorporation ? "Corporation" : "")),
      "has_tax_incentive": (hasTaxIncentive == true) ? 1 : 0,
      "tax_incentive_entity": _entityController.text.trim(),
      // application date as yyyy-mm-dd (if selected)
      "application_date": selectedDate?.toIso8601String().split('T').first,
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Application2FormScreen(initialData: data)),
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI kept intact, only changed Next to pass data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Form', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("APPLICANT FORM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
            const SizedBox(height: 16),
            const Text("Basic Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),

            _buildCheckboxRow(label: 'New Application', value: isNewApplication, onChanged: (v) {
              setState(() {
                isNewApplication = v ?? false;
                if (isNewApplication) isRenewal = false;
              });
            }),
            _buildCheckboxRow(label: 'Renewal', value: isRenewal, onChanged: (v) {
              setState(() {
                isRenewal = v ?? false;
                if (isRenewal) isNewApplication = false;
              });
            }),
            const SizedBox(height: 16),

            const Text("Mode of Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
            _buildCheckboxRow(label: 'Annually', value: isAnnually, onChanged: (v) {
              setState(() {
                isAnnually = v ?? false;
                if (isAnnually) {
                  isSemiAnnually = false;
                  isQuarterly = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Semi-Annually', value: isSemiAnnually, onChanged: (v) {
              setState(() {
                isSemiAnnually = v ?? false;
                if (isSemiAnnually) {
                  isAnnually = false;
                  isQuarterly = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Quarterly', value: isQuarterly, onChanged: (v) {
              setState(() {
                isQuarterly = v ?? false;
                if (isQuarterly) {
                  isAnnually = false;
                  isSemiAnnually = false;
                }
              });
            }),
            const SizedBox(height: 16),

            const Text("Date of Application:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? now,
                  firstDate: DateTime(now.year - 1, now.month, now.day),
                  lastDate: DateTime(now.year + 1, now.month, now.day),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: Text(selectedDate != null ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}" : 'Select a date'),
              ),
            ),
            const SizedBox(height: 16),

            TextField(controller: _tinController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'TIN No.:', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            const Text("Type of Business", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
            _buildCheckboxRow(label: 'Single', value: isSingle, onChanged: (v) {
              setState(() {
                isSingle = v ?? false;
                if (isSingle) {
                  isPartnership = false;
                  isCorporation = false;
                  isCooperative = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Partnership', value: isPartnership, onChanged: (v) {
              setState(() {
                isPartnership = v ?? false;
                if (isPartnership) {
                  isSingle = false;
                  isCorporation = false;
                  isCooperative = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Corporation', value: isCorporation, onChanged: (v) {
              setState(() {
                isCorporation = v ?? false;
                if (isCorporation) {
                  isSingle = false;
                  isPartnership = false;
                  isCooperative = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Cooperative', value: isCooperative, onChanged: (v) {
              setState(() {
                isCooperative = v ?? false;
                if (isCooperative) {
                  isSingle = false;
                  isPartnership = false;
                  isCorporation = false;
                }
              });
            }),
            const SizedBox(height: 16),

            const Text("Amendment: From", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
            _buildCheckboxRow(label: 'Single', value: isFromSingle, onChanged: (v) {
              setState(() {
                isFromSingle = v ?? false;
                if (isFromSingle) {
                  isFromPartnership = false;
                  isFromCorporation = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Partnership', value: isFromPartnership, onChanged: (v) {
              setState(() {
                isFromPartnership = v ?? false;
                if (isFromPartnership) {
                  isFromSingle = false;
                  isFromCorporation = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Corporation', value: isFromCorporation, onChanged: (v) {
              setState(() {
                isFromCorporation = v ?? false;
                if (isFromCorporation) {
                  isFromSingle = false;
                  isFromPartnership = false;
                }
              });
            }),
            const SizedBox(height: 16),

            const Text("To", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
            _buildCheckboxRow(label: 'Single', value: isToSingle, onChanged: (v) {
              setState(() {
                isToSingle = v ?? false;
                if (isToSingle) {
                  isToPartnership = false;
                  isToCorporation = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Partnership', value: isToPartnership, onChanged: (v) {
              setState(() {
                isToPartnership = v ?? false;
                if (isToPartnership) {
                  isToSingle = false;
                  isToCorporation = false;
                }
              });
            }),
            _buildCheckboxRow(label: 'Corporation', value: isToCorporation, onChanged: (v) {
              setState(() {
                isToCorporation = v ?? false;
                if (isToCorporation) {
                  isToSingle = false;
                  isToPartnership = false;
                }
              });
            }),
            const SizedBox(height: 16),

            const Text("Are you enjoying tax incentive from any Government entity?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8),
              Row(children: [
              Radio<bool>(value: true, groupValue: hasTaxIncentive, onChanged: (bool? value) {
              setState(() {
              hasTaxIncentive = value;
                  });
                 }),
            const Text('Yes'),
            const SizedBox(width: 24),
               Radio<bool>(value: false, groupValue: hasTaxIncentive, onChanged: (bool? value) {
               setState(() {
            hasTaxIncentive = value;
            // ⭐ FIX: Clear the controller when 'No' is selected
            if (value == false) {
                _entityController.clear(); 
               }
              });
              }),
              const Text('No'),
                  ]),
            const SizedBox(height: 8),
                  if (hasTaxIncentive == true)
                   TextField(controller: _entityController, decoration: const InputDecoration(labelText: 'Please Specify the Entity', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            const Text("Name of the Taxpayer/Registrant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 16),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _accountNumberController, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _tradeNameController, decoration: const InputDecoration(labelText: 'Trade Name/Franchise', border: OutlineInputBorder())),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: _goToNext,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: const Text('Next', style: TextStyle(fontSize: 16, color: (Colors.white))),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Screen 2
class Application2FormScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const Application2FormScreen({super.key, required this.initialData});

  @override
  State<Application2FormScreen> createState() => _Application2FormScreenState();
}

class _Application2FormScreenState extends State<Application2FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _businessAddress = TextEditingController(text: "");
  final TextEditingController _postalCode = TextEditingController();
  final TextEditingController _ownerAddress = TextEditingController(text: "");
  final TextEditingController _ownerEmail = TextEditingController(text: "");
  final TextEditingController _ownerMobile = TextEditingController(text: "");
  final TextEditingController _emergencyContact = TextEditingController();
  final TextEditingController _emergencyEmail = TextEditingController();
  final TextEditingController _emergencyMobile = TextEditingController();
  final TextEditingController _businessArea = TextEditingController();
  final TextEditingController _employeesTotal = TextEditingController(text: "");
  final TextEditingController _employeesWithLGU = TextEditingController(text: "");

  bool isRented = false;
  final TextEditingController _lessorName = TextEditingController();
  final TextEditingController _lessorAddress = TextEditingController();
  final TextEditingController _lessorContact = TextEditingController();
  final TextEditingController _lessorEmail = TextEditingController();
  final TextEditingController _monthlyRental = TextEditingController();

  @override
  void dispose() {
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
    _lessorName.dispose();
    _lessorAddress.dispose();
    _lessorContact.dispose();
    _lessorEmail.dispose();
    _monthlyRental.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) => null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  void _goToNext() {
    // merge initialData (from screen1) with screen2 values
    final merged = {
      ...widget.initialData,
      // application detail keys expected by DB (top-level in current Flask)
      "business_address": _businessAddress.text.trim(),
      "postal_code": _postalCode.text.trim(),
      "owner_address": _ownerAddress.text.trim(),
      "owner_email": _ownerEmail.text.trim(),
      "owner_mobile": _ownerMobile.text.trim(),
      "emergency_contact": _emergencyContact.text.trim(),
      "emergency_email": _emergencyEmail.text.trim(),
      "emergency_mobile": _emergencyMobile.text.trim(),
      "business_area": _businessArea.text.trim(),
      "employees_total": _employeesTotal.text.trim(),
      "employees_with_lgu": _employeesWithLGU.text.trim(),
      "is_rented": isRented ? 1 : 0,
      // lessor fields
      "lessor_name": _lessorName.text.trim(),
      "lessor_address": _lessorAddress.text.trim(),
      "lessor_email": _lessorEmail.text.trim(),
      "lessor_mobile": _lessorContact.text.trim(),
      "monthly_rent": _monthlyRental.text.trim(),
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => Application3FormScreen(accumulatedData: merged)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Form'), backgroundColor: const Color(0xFF1A2B47)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("2. OTHER INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Note: For RENEWAL APPLICATIONS, do not fill up this section unless information have changed ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 10),
            _buildTextField("Business Address", _businessAddress),
            _buildTextField("Postal Code", _postalCode),
            _buildTextField("Owner's Address", _ownerAddress),
            _buildTextField("Email Address", _ownerEmail),
            _buildTextField("Mobile No.", _ownerMobile),
            _buildTextField("Emergency Contact Person", _emergencyContact),
            _buildTextField("Emergency Email", _emergencyEmail),
            _buildTextField("Emergency Mobile No.", _emergencyMobile),
            _buildTextField("Business Area (in sq. m.)", _businessArea),
            _buildTextField("Total No. of Employees", _employeesTotal),
            _buildTextField("No. of Employees Residing with LGU", _employeesWithLGU),

            const SizedBox(height: 12),
            CheckboxListTile(title: const Text("Business Place is Rented"), value: isRented, onChanged: (value) {
              setState(() => isRented = value ?? false);
            }),
            if (isRented) ...[
              _buildTextField("Lessor's Full Name", _lessorName),
              _buildTextField("Lessor's Address", _lessorAddress),
              _buildTextField("Lessor's Tel/Mobile No.", _lessorContact),
              _buildTextField("Lessor's Email", _lessorEmail),
              _buildTextField("Monthly Rental", _monthlyRental),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _goToNext,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: const Text('Next', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Screen 3 (final submit)
class Application3FormScreen extends StatefulWidget {
  final Map<String, dynamic> accumulatedData;
  const Application3FormScreen({super.key, required this.accumulatedData});

  @override
  State<Application3FormScreen> createState() => _Application3FormScreenState();
}

class _Application3FormScreenState extends State<Application3FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _lineOfBusiness = TextEditingController(text: "");
  final TextEditingController _numOfUnits = TextEditingController();
  final TextEditingController _capitalization = TextEditingController(text: "");
  final TextEditingController _grossSalesEssential = TextEditingController();
  final TextEditingController _grossSalesNonEssential = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _lineOfBusiness.dispose();
    _numOfUnits.dispose();
    _capitalization.dispose();
    _grossSalesEssential.dispose();
    _grossSalesNonEssential.dispose();
    super.dispose();
  }

  Future<void> _submitFinalForm() async {
    setState(() => _isSubmitting = true);

    // get user_id from SharedPreferences (support int or string)
    final prefs = await SharedPreferences.getInstance();
    String? userIdStr = prefs.getString('user_id');
    if (userIdStr == null) {
      final userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) userIdStr = userIdInt.toString();
    }

    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No user found. Please Log In again.")));
      setState(() => _isSubmitting = false);
      return;
    }

    // Build final map. Note: your current Flask server expects top-level keys like "first_name", "businessName", "account_number", "application_type", etc.
    final Map<String, dynamic> finalData = {
      "user_id": userIdStr,
      // merge existing accumulatedData (from screens 1 & 2)
      ...widget.accumulatedData,
      // application_date was possibly included from screen1; ensure it's a string
      "application_date": widget.accumulatedData["application_date"] ?? DateTime.now().toIso8601String().split('T').first,
      // business_activity (we include these fields for completeness - your current Flask doesn't insert these yet but it's fine to send)
      "line_of_business": _lineOfBusiness.text.trim(),
      "num_of_units": int.tryParse(_numOfUnits.text.trim()) ?? 0,
      "capitalization": double.tryParse(_capitalization.text.trim())?.toString() ?? "0.0",
      "gross_sales_essential": double.tryParse(_grossSalesEssential.text.trim())?.toString() ?? "0.0",
      "gross_sales_non_essential": double.tryParse(_grossSalesNonEssential.text.trim())?.toString() ?? "0.0",
    };

    // For debugging: inspect the final payload
    print("==== Submitting application payload ====");
    print(finalData);

    try {
      final result = await ApiService.submitApplication(finalData);
      print("Response from server: $result");

      if (result["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application submitted successfully!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result["message"] ?? 'Submission failed'}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Activity'), backgroundColor: const Color(0xFF1A2B47)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("3. BUSINESS ACTIVITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildTextField("Line of Business", _lineOfBusiness),
            _buildTextField("No. of Units", _numOfUnits, isNumber: true),
            _buildTextField("Capitalization (₱)", _capitalization, isNumber: true),
            _buildTextField("Gross/Sales Receipts (Essential)", _grossSalesEssential, isNumber: true),
            _buildTextField("Gross/Sales Receipts (Non-Essential)", _grossSalesNonEssential, isNumber: true),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _submitFinalForm();
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';



// class ApplicationFormScreen extends StatefulWidget {
//   const ApplicationFormScreen({super.key});

//   @override
//   _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
// }

// class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
//   bool isNewApplication = false;
//   bool isRenewal = false;
  
//   bool isAnnually = false;
//   bool isSemiAnnually = false;
//   bool isQuarterly = false;

//   bool isSingle = false;
//   bool isPartnership = false;
//   bool isCorporation = false;
//   bool isCooperative = false;
  
//   bool isFromSingle = false;
//   bool isFromPartnership = false;
//   bool isFromCorporation = false;
  
//   bool isToSingle = false;
//   bool isToPartnership = false;
//   bool isToCorporation = false;
  
//   bool? hasTaxIncentive = false;
  
//   DateTime? selectedDate;

//   final TextEditingController _tinController = TextEditingController();
//   final TextEditingController _entityController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _middleNameController = TextEditingController();
//   final TextEditingController _businessNameController = TextEditingController();
//   final TextEditingController _accountNumberController = TextEditingController();
//   final TextEditingController _tradeNameController = TextEditingController();

//   @override
//   void dispose() { 
//     _tinController.dispose();
//     _entityController.dispose();
//     _lastNameController.dispose();
//     _firstNameController.dispose();
//     _middleNameController.dispose();
//     _businessNameController.dispose();
//     _accountNumberController.dispose();
//     _tradeNameController.dispose();
//     super.dispose();
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Application Form', style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF1A2B47),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Section: Form Title
//             const Text(
//               "APPLICANT FORM", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18.0,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Section: Application Type
//             const Text(
//               "Basic Information",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             _buildCheckboxRow(
//               label: 'New Application',
//               value: isNewApplication,
//               onChanged: (value) {
//                 setState(() {
//                   isNewApplication = value ?? false;
//                   if (isNewApplication) isRenewal = false;
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Renewal',
//               value: isRenewal,
//               onChanged: (value) {
//                 setState(() {
//                   isRenewal = value ?? false;
//                   if (isRenewal) isNewApplication = false;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
          
//             const Text(
//               "Mode of Payment", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
            
//             _buildCheckboxRow(
//               label: 'Annually',
//               value: isAnnually,
//               onChanged: (value) {
//                 setState(() {
//                   isAnnually = value ?? false;
//                   if (isAnnually) {
//                     isSemiAnnually = false;
//                     isQuarterly = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Semi-Annually',
//               value: isSemiAnnually,
//               onChanged: (value) {
//                 setState(() {
//                   isSemiAnnually = value ?? false;
//                   if (isSemiAnnually) {
//                     isAnnually = false;
//                     isQuarterly = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Quarterly',
//               value: isQuarterly,
//               onChanged: (value) {
//                 setState(() {
//                   isQuarterly = value ?? false;
//                   if (isQuarterly) {
//                     isAnnually = false;
//                     isSemiAnnually = false;
//                   }
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             const Text(
//               "Date of Application:", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
  
//             InkWell(
//               onTap: () async {
//                 final now = DateTime.now();
//                 final DateTime? picked = await showDatePicker(
//                   context: context,
//                   initialDate: selectedDate ?? now,
//                   firstDate: DateTime(now.year - 1, now.month, now.day),
//                   lastDate: DateTime(now.year + 1, now.month, now.day),
//                 );
//                 if (picked != null) {
//                   setState(() {
//                     selectedDate = picked;
//                   });
//                 }
//               },
//               child: InputDecorator(
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 ),
//                 child: Text(
//                   selectedDate != null 
//                       ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}"
//                       : 'Select a date',
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             TextField(
//               controller: _tinController,
//               keyboardType: TextInputType.number,
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//               decoration: const InputDecoration(
//                 labelText: 'TIN No.:',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
          
//             const Text(
//               "Type of Business", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             _buildCheckboxRow(
//               label: 'Single',
//               value: isSingle,
//               onChanged: (value) {
//                 setState(() {
//                   isSingle = value ?? false;
//                   if (isSingle) {
//                     isPartnership = false;
//                     isCorporation = false;
//                     isCooperative = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Partnership',
//               value: isPartnership,
//               onChanged: (value) {
//                 setState(() {
//                   isPartnership = value ?? false;
//                   if (isPartnership) {
//                     isSingle = false;
//                     isCorporation = false;
//                     isCooperative = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Corporation',
//               value: isCorporation,
//               onChanged: (value) {
//                 setState(() {
//                   isCorporation = value ?? false;
//                   if (isCorporation) {
//                     isSingle = false;
//                     isPartnership = false;
//                     isCooperative = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Cooperative',
//               value: isCooperative,
//               onChanged: (value) {
//                 setState(() {
//                   isCooperative = value ?? false;
//                   if (isCooperative) {
//                     isSingle = false;
//                     isPartnership = false;
//                     isCorporation = false;
//                   }
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             // Section: Amendment From
//             const Text(
//               "Amendment: From", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             // Amendment From options
//             _buildCheckboxRow(
//               label: 'Single',
//               value: isFromSingle,
//               onChanged: (value) {
//                 setState(() {
//                   isFromSingle = value ?? false;
//                   if (isFromSingle) {
//                     isFromPartnership = false;
//                     isFromCorporation = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Partnership',
//               value: isFromPartnership,
//               onChanged: (value) {
//                 setState(() {
//                   isFromPartnership = value ?? false;
//                   if (isFromPartnership) {
//                     isFromSingle = false;
//                     isFromCorporation = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Corporation',
//               value: isFromCorporation,
//               onChanged: (value) {
//                 setState(() {
//                   isFromCorporation = value ?? false;
//                   if (isFromCorporation) {
//                     isFromSingle = false;
//                     isFromPartnership = false;
//                   }
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             const Text(
//               "To", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             _buildCheckboxRow(
//               label: 'Single',
//               value: isToSingle,
//               onChanged: (value) {
//                 setState(() {
//                   isToSingle = value ?? false;
//                   if (isToSingle) {
//                     isToPartnership = false;
//                     isToCorporation = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Partnership',
//               value: isToPartnership,
//               onChanged: (value) {
//                 setState(() {
//                   isToPartnership = value ?? false;
//                   if (isToPartnership) {
//                     isToSingle = false;
//                     isToCorporation = false;
//                   }
//                 });
//               },
//             ),
//             _buildCheckboxRow(
//               label: 'Corporation',
//               value: isToCorporation,
//               onChanged: (value) {
//                 setState(() {
//                   isToCorporation = value ?? false;
//                   if (isToCorporation) {
//                     isToSingle = false;
//                     isToPartnership = false;
//                   }
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
            
//             const Text(
//               "Are you enjoying tax incentive from any Government entity?", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             Row(
//                 children: [
//                   Radio<bool>(
//                     value: true,
//                     groupValue: hasTaxIncentive,
//                     onChanged: (bool? value) {
//                       setState(() {
//                         hasTaxIncentive = value;
//                       });
//                     },
//                   ),
//                   const Text('Yes'),
//                   const SizedBox(width: 24),
//                   Radio<bool>(
//                     value: false,
//                     groupValue: hasTaxIncentive,
//                     onChanged: (bool? value) {
//                       setState(() {
//                         hasTaxIncentive = value;
//                       });
//                     },
//                   ),
//                   const Text('No'),
//                 ],
//               ),

//             const SizedBox(height: 8),
            
//             if (hasTaxIncentive == true)
//               TextField(
//                 controller: _entityController,
//                 decoration: const InputDecoration(
//                   labelText: 'Please Specify the Entity',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             const SizedBox(height: 16),
            
//             const Text(
//               "Name of the Taxpayer/Registrant", 
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             TextField(
//               controller: _lastNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Last Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _firstNameController,
//               decoration: const InputDecoration(
//                 labelText: 'First Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _middleNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Middle Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _businessNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Business Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _accountNumberController,
//               decoration: const InputDecoration(
//                 labelText: 'Account Number',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _tradeNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Trade Name/Franchise',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 24),
            
            
//             Center(
//               child: ElevatedButton(
//                 onPressed: _submitForm,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1A2B47),
//                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//                 ),
//                 child: const Text('Next', style: TextStyle(fontSize: 16, color:(Colors.white))),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCheckboxRow({
//     required String label,
//     required bool value,
//     required Function(bool?) onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           Checkbox(value: value, onChanged: onChanged),
//           Text(label),
//         ],
//       ),
//     );
//   }

//   void _submitForm() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const Application2FormScreen()),
//     );
//   }
// }

// class Application2FormScreen extends StatefulWidget {
//   const Application2FormScreen({super.key});

//   @override
//   State<Application2FormScreen> createState() => _Application2FormScreenState();
// }

// class _Application2FormScreenState extends State<Application2FormScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _businessAddress = TextEditingController(text: "");
//   final TextEditingController _postalCode = TextEditingController();
//   final TextEditingController _ownerAddress = TextEditingController(text: "");
//   final TextEditingController _ownerEmail = TextEditingController(text: "");
//   final TextEditingController _ownerMobile = TextEditingController(text: "");
//   final TextEditingController _emergencyContact = TextEditingController();
//   final TextEditingController _emergencyEmail = TextEditingController();
//   final TextEditingController _emergencyMobile = TextEditingController();
//   final TextEditingController _businessArea = TextEditingController();
//   final TextEditingController _employeesTotal = TextEditingController(text: "");
//   final TextEditingController _employeesWithLGU = TextEditingController(text: "");

//   bool isRented = false;
//   final TextEditingController _lessorName = TextEditingController();
//   final TextEditingController _lessorAddress = TextEditingController();
//   final TextEditingController _lessorContact = TextEditingController();
//   final TextEditingController _lessorEmail = TextEditingController();
//   final TextEditingController _monthlyRental = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Application Form')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("2. OTHER INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//               const Text("Note: For RENEWAL APPLICATIONS, do not fill up this section unless information have changed ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
//               const SizedBox(height: 10),
//               _buildTextField("Business Address", _businessAddress),
//               _buildTextField("Postal Code", _postalCode),
//               _buildTextField("Owner's Address", _ownerAddress),
//               _buildTextField("Email Address", _ownerEmail),
//               _buildTextField("Mobile No.", _ownerMobile),
//               _buildTextField("Emergency Contact Person", _emergencyContact),
//               _buildTextField("Emergency Email", _emergencyEmail),
//               _buildTextField("Emergency Mobile No.", _emergencyMobile),
//               _buildTextField("Business Area (in sq. m.)", _businessArea),
//               _buildTextField("Total No. of Employees", _employeesTotal),
//               _buildTextField("No. of Employees Residing with LGU", _employeesWithLGU),

//               const SizedBox(height: 12),
//               CheckboxListTile(
//                 title: const Text("Business Place is Rented"),
//                 value: isRented,
//                 onChanged: (value) {
//                   setState(() => isRented = value!);
//                 },
//               ),
//               if (isRented) ...[
//                 _buildTextField("Lessor's Full Name", _lessorName),
//                 _buildTextField("Lessor's Address", _lessorAddress),
//                 _buildTextField("Lessor's Tel/Mobile No.", _lessorContact),
//                 _buildTextField("Lessor's Email", _lessorEmail),
//                 _buildTextField("Monthly Rental", _monthlyRental),
//               ],

//               const SizedBox(height: 24),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const Application3FormScreen(),
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A2B47),
//                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//                   ),
//                   child: const Text('Next', style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         validator: (value) => null,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
// }

// class Application3FormScreen extends StatefulWidget {
//   const Application3FormScreen({super.key});

//   @override
//   State<Application3FormScreen> createState() => _Application3FormScreenState();
// }

// class _Application3FormScreenState extends State<Application3FormScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _lineOfBusiness = TextEditingController(text: "");
//   final TextEditingController _numOfUnits = TextEditingController();
//   final TextEditingController _capitalization = TextEditingController(text: "");
//   final TextEditingController _grossSalesEssential = TextEditingController();
//   final TextEditingController _grossSalesNonEssential = TextEditingController();

//   /// 👉 Submit to backend API
//   Future<void> _submitFinalForm() async {

//   final prefs = await SharedPreferences.getInstance();
//   final userId = prefs.getString('user_id');

//     if (userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Error: No user found. Please Log In again.")),
//       );
//       return;
//     }

//     final formData = {
//       "user_id": userId,
//       "business_activity": {
//         "line_of_business": _lineOfBusiness.text,
//         "num_of_units": _numOfUnits.text,
//         "capitalization": _capitalization.text,
//         "gross_sales_essential": _grossSalesEssential.text,
//         "gross_sales_non_essential": _grossSalesNonEssential.text,
//       }
//       // ⚠️ Later, you will merge this with taxpayer + business + details
//     };

//     print("Submitting data: $formData"); // debug log
 
//  try {
//     final result = await ApiService.submitApplication(formData);

//     if (result["status"] == "success") {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Application submitted successfully!")),
//       );
//       Navigator.popUntil(context, (route) => route.isFirst);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${result["message"]}")),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Error: $e")),
//     );
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Business Activity')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "3. BUSINESS ACTIVITY",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//               const SizedBox(height: 10),

//               _buildTextField("Line of Business", _lineOfBusiness),
//               _buildTextField("No. of Units", _numOfUnits, isNumber: true),
//               _buildTextField("Capitalization (₱)", _capitalization, isNumber: true),
//               _buildTextField("Gross/Sales Receipts (Essential)", _grossSalesEssential, isNumber: true),
//               _buildTextField("Gross/Sales Receipts (Non-Essential)", _grossSalesNonEssential, isNumber: true),

//               const SizedBox(height: 24),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       _submitFinalForm(); // 👉 call API
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A2B47),
//                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
//                   ),
//                   child: const Text('Submit', style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Reusable textfield builder
//   Widget _buildTextField(String label, TextEditingController controller,
//       {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         validator: (value) =>
//             value == null || value.isEmpty ? 'Required' : null,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
// }


