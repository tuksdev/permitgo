import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🛑 NEW IMPORT: For fetching user_id
// import '../api_services.dart'; // Ensure this is imported for real API calls
import 'review.dart'; 
import '../api_services.dart';

//
// Screen 1 = ApplicationFormScreen (Taxpayer)
// Screen 2 = Application2FormScreen (Other Information)
// Screen 3 = Application3FormScreen (Business Activity)
//

// -----------------------------------------------------------------------------
/// Screen 1: Taxpayer Information (Auto-filled Name)
// -----------------------------------------------------------------------------
class ApplicationFormScreen extends StatefulWidget {
  final String? applicationId;
  const ApplicationFormScreen({super.key, this.applicationId});

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🛑 REMOVED: isNewApplication and isRenewal booleans

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
  bool _isUserDataLoading = true; // 🛑 NEW: Loading state

  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _entityController = TextEditingController();
  // Name fields will be pre-filled:
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); 
    _loadUserDataAndPrefill(); // 🛑 NEW: Load user data
  }

  // 🛑 NEW FUNCTION: Loads user profile data (name)
  Future<void> _loadUserDataAndPrefill() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');

    if (currentUserId != null) {
      
      // 🛑 REAL API CALL 🛑
      final response = await ApiService.fetchUserProfile(currentUserId);
      
      if (response['status'] == 'success' && response['user_data'] != null) {
        final userData = response['user_data'];
        
        setState(() {
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _middleNameController.text = userData['middle_name'] ?? '';
          _isUserDataLoading = false;
        });
        
      } else {
        // Handle failure (e.g., user not found, server error)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user profile: ${response['message'] ?? 'Unknown error'}')),
        );
        setState(() {
            _isUserDataLoading = false;
        });
      }
    } else {
      // If user ID is missing
      setState(() {
        _isUserDataLoading = false;
      });
    }
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
    super.dispose();
  }

  void _goToNext() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form before proceeding.')),
      );
      return;
    }

    // 🛑 Validation for required checkbox groups
    if (!isAnnually && !isSemiAnnually && !isQuarterly) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mode of Payment.')),
      );
      return;
    }
    if (!isSingle && !isPartnership && !isCorporation && !isCooperative) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Type of Business.')),
      );
      return;
    }

    // build partial data map from screen 1
    final Map<String, dynamic> data = {
      // Name fields (pre-filled from user data)
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "middle_name": _middleNameController.text.trim(),

      // Other fields
      "trade_name": _tradeNameController.text.trim(),
      "businessName": _businessNameController.text.trim(),
      "account_number": _accountNumberController.text.trim(),
      "tin_no": _tinController.text.trim(),

      // Application type defaults to "New Application" here
      "application_type": "New Application", // 🛑 DEFAULTED VALUE
      
      "mode_of_payment": isAnnually ? "Annually" : (isSemiAnnually ? "Semi-Annually" : (isQuarterly ? "Quarterly" : "")),
      "business_type": isSingle ? "Single" : (isPartnership ? "Partnership" : (isCorporation ? "Corporation" : (isCooperative ? "Cooperative" : ""))),
      "amendment_from": isFromSingle ? "Single" : (isFromPartnership ? "Partnership" : (isFromCorporation ? "Corporation" : "")),
      "amendment_to": isToSingle ? "Single" : (isToPartnership ? "Partnership" : (isToCorporation ? "Corporation" : "")),
      "has_tax_incentive": (hasTaxIncentive == true) ? 1 : 0,
      "tax_incentive_entity": _entityController.text.trim(),
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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool isRequired = true, List<TextInputFormatter>? formatters, int? maxLength, bool isReadOnly = false}) {
    List<TextInputFormatter> finalFormatters = formatters ?? [];
    if (maxLength != null) {
        finalFormatters.add(LengthLimitingTextInputFormatter(maxLength));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: finalFormatters.isNotEmpty ? finalFormatters : null,
        readOnly: isReadOnly, // 🛑 Set Read-Only
        style: TextStyle(color: isReadOnly ? Colors.black87 : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          fillColor: isReadOnly ? Colors.grey[200] : Colors.white, // 🛑 Visual Cue for Read-Only
          filled: isReadOnly,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserDataLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A2B47)),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Form (1 of 3)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B47),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form( 
          key: _formKey, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("APPLICANT FORM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
              const SizedBox(height: 16),

              // 🛑 REMOVED APPLICATION TYPE SECTION

              // --- Mode of Payment ---
              const Text("Mode of Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              _buildCheckboxRow(label: 'Annually', value: isAnnually, onChanged: (v) {
                setState(() {
                  isAnnually = v ?? false;
                  if (isAnnually) { isSemiAnnually = false; isQuarterly = false; }
                });
              }),
              _buildCheckboxRow(label: 'Semi-Annually', value: isSemiAnnually, onChanged: (v) {
                setState(() {
                  isSemiAnnually = v ?? false;
                  if (isSemiAnnually) { isAnnually = false; isQuarterly = false; }
                });
              }),
              _buildCheckboxRow(label: 'Quarterly', value: isQuarterly, onChanged: (v) {
                setState(() {
                  isQuarterly = v ?? false;
                  if (isQuarterly) { isAnnually = false; isSemiAnnually = false; }
                });
              }),
              const SizedBox(height: 16),

              // --- Date of Application (Read-Only) ---
              const Text("Date of Application (Auto-Generated):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(), 
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  selectedDate != null ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}" : 'Date not set',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),

              // --- TIN Field (Number Only, Max Length 12) ---
              _buildTextField('TIN No.:', _tinController, 
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 12,
              ),
              
              // --- Type of Business ---
              const Text("Type of Business", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              _buildCheckboxRow(label: 'Single', value: isSingle, onChanged: (v) {
                setState(() {
                  isSingle = v ?? false;
                  if (isSingle) { isPartnership = false; isCorporation = false; isCooperative = false; }
                });
              }),
              _buildCheckboxRow(label: 'Partnership', value: isPartnership, onChanged: (v) {
                setState(() {
                  isPartnership = v ?? false;
                  if (isPartnership) { isSingle = false; isCorporation = false; isCooperative = false; }
                });
              }),
              _buildCheckboxRow(label: 'Corporation', value: isCorporation, onChanged: (v) {
                setState(() {
                  isCorporation = v ?? false;
                  if (isCorporation) { isSingle = false; isPartnership = false; isCooperative = false; }
                });
              }),
              _buildCheckboxRow(label: 'Cooperative', value: isCooperative, onChanged: (v) {
                setState(() {
                  isCooperative = v ?? false;
                  if (isCooperative) { isSingle = false; isPartnership = false; isCorporation = false; }
                });
              }),
              const SizedBox(height: 16),

              // --- Amendment From / To (Retained as Checkbox groups) ---
              const Text("Amendment: From", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              _buildCheckboxRow(label: 'Single', value: isFromSingle, onChanged: (v) {
                setState(() {
                  isFromSingle = v ?? false;
                  if (isFromSingle) { isFromPartnership = false; isFromCorporation = false; }
                });
              }),
              _buildCheckboxRow(label: 'Partnership', value: isFromPartnership, onChanged: (v) {
                setState(() {
                  isFromPartnership = v ?? false;
                  if (isFromPartnership) { isFromSingle = false; isFromCorporation = false; }
                });
              }),
              _buildCheckboxRow(label: 'Corporation', value: isFromCorporation, onChanged: (v) {
                setState(() {
                  isFromCorporation = v ?? false;
                  if (isFromCorporation) { isFromSingle = false; isFromPartnership = false; }
                });
              }),
              const SizedBox(height: 16),

              const Text("To", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              _buildCheckboxRow(label: 'Single', value: isToSingle, onChanged: (v) {
                setState(() {
                  isToSingle = v ?? false;
                  if (isToSingle) { isToPartnership = false; isToCorporation = false; }
                });
              }),
              _buildCheckboxRow(label: 'Partnership', value: isToPartnership, onChanged: (v) {
                setState(() {
                  isToPartnership = v ?? false;
                  if (isToPartnership) { isToSingle = false; isToCorporation = false; }
                });
              }),
              _buildCheckboxRow(label: 'Corporation', value: isToCorporation, onChanged: (v) {
                setState(() {
                  isToCorporation = v ?? false;
                  if (isToCorporation) { isToSingle = false; isToPartnership = false; }
                });
              }),
              const SizedBox(height: 16),

              // --- Tax Incentive Radio Buttons ---
              const Text("Are you enjoying tax incentive from any Government entity?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 8),
              Row(children: [
                Radio<bool>(value: true, groupValue: hasTaxIncentive, onChanged: (bool? value) {
                  setState(() { hasTaxIncentive = value; });
                }),
                const Text('Yes'),
                const SizedBox(width: 24),
                Radio<bool>(value: false, groupValue: hasTaxIncentive, onChanged: (bool? value) {
                  setState(() { 
                    hasTaxIncentive = value;
                    if (value == false) { _entityController.clear(); }
                  });
                }),
                const Text('No'),
              ]),
              const SizedBox(height: 8),
              if (hasTaxIncentive == true)
                _buildTextField('Please Specify the Entity', _entityController),
              const SizedBox(height: 16),

              // --- Taxpayer Name Fields (Pre-filled and Read-Only) ---
              const Text("Name of the Taxpayer/Registrant (Auto-Filled)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 16),
              _buildTextField('Last Name', _lastNameController, isReadOnly: true),
              _buildTextField('First Name', _firstNameController, isReadOnly: true),
              _buildTextField('Middle Name', _middleNameController, isRequired: false, isReadOnly: true),
              
              // Other required fields:
              _buildTextField('Business Name', _businessNameController),
              _buildTextField('Account Number', _accountNumberController),
              _buildTextField('Trade Name/Franchise', _tradeNameController, isRequired: false),
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
/// Screen 2: Other Information
// -----------------------------------------------------------------------------
class Application2FormScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const Application2FormScreen({super.key, required this.initialData});

  @override
  State<Application2FormScreen> createState() => _Application2FormScreenState();
}

class _Application2FormScreenState extends State<Application2FormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBarangay;
  final List<String> _barangay = [
    'Minaga Este',
    'Minanga Weste',
    'Villa Leonora',
    'Mala Este',
    'Mala Weste',
    'Leron',
    'Sta. Maria',
    'Centro',
    'Centro West',
    'Cabaritan',
    'San Isidro',
    'Paddaya Este',
    'Paddaya Weste',
    'Balza'
    // Add more barangay options as needed
  ];

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
 
  bool _isUserDataLoading = true;

  @override
  void initState() {
    super.initState();
    // 🛑 1. Auto-fill Postal Code
    _postalCode.text = "3511";
    _loadUserDataAndPrefill();
  }

  // 🛑 NEW FUNCTION: Load user profile data (email/mobile)
  Future<void> _loadUserDataAndPrefill() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');

    if (currentUserId != null) {
      final response = await ApiService.fetchUserProfile(currentUserId);
      
      if (response['status'] == 'success' && response['user_data'] != null) {
        final userData = response['user_data'];
        
        setState(() {
          // 🛑 2. Auto-fill Email and Mobile
          _ownerEmail.text = userData['email'] ?? '';
          _ownerMobile.text = userData['mobile_number'] ?? '';
          _isUserDataLoading = false;
        });
        
      } else {
        // Handle API failure
        _isUserDataLoading = false;
      }
    } else {
      _isUserDataLoading = false;
    }
    setState(() {});
  }

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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, bool isRequired = true, List<TextInputFormatter>? formatters, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          if (label.contains('Email') && value!.isNotEmpty && !value.contains('@')) {
            return 'Enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  void _goToNext() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form before proceeding.')),
      );
      return;
    }
    
    final businessAddress = "$_selectedBarangay, Buguey,Cagayan";

    final merged = {
      ...widget.initialData,
      "business_address": businessAddress,
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
      "lessor_name": isRented ? _lessorName.text.trim() : "",
      "lessor_address": isRented ? _lessorAddress.text.trim() : "",
      "lessor_email": isRented ? _lessorEmail.text.trim() : "",
      "lessor_mobile": isRented ? _lessorContact.text.trim() : "",
      "monthly_rent": isRented ? _monthlyRental.text.trim() : "",
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => Application3FormScreen(accumulatedData: merged)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isUserDataLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A2B47)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Application Form (2 of 3)'), backgroundColor: const Color(0xFF1A2B47)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("2. OTHER INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            //const Text("Note: For RENEWAL APPLICATIONS, do not fill up this section unless information have changed ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 10),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Business Address (Barangay)',
                border: OutlineInputBorder(),
              ),
              value: _selectedBarangay,
              items: _barangay.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBarangay = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a Barangay' : null,
            ),
            const SizedBox(height: 12),
            
            _buildTextField("Postal Code", _postalCode, isReadOnly: true, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),

            _buildTextField("Owner's Address", _ownerAddress),

            _buildTextField("Email Address", _ownerEmail, keyboardType: TextInputType.emailAddress),
            
            _buildTextField("Mobile No.", _ownerMobile, isReadOnly: true, keyboardType: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly]),
            
            _buildTextField("Emergency Contact Person", _emergencyContact, isRequired: false),
            
            _buildTextField("Emergency Email", _emergencyEmail, keyboardType: TextInputType.emailAddress, isRequired: false),
            
            _buildTextField("Emergency Mobile No.", _emergencyMobile, keyboardType: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly], isRequired: false),
            
            _buildTextField("Business Area (in sq. m.)", _businessArea, keyboardType: const TextInputType.numberWithOptions(decimal: true), formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
            
            _buildTextField("Total No. of Employees", _employeesTotal, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
            _buildTextField("No. of Employees Residing with LGU", _employeesWithLGU, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),

            const SizedBox(height: 12),
            CheckboxListTile(title: const Text("Business Place is Rented"), value: isRented, onChanged: (value) {
              setState(() => isRented = value ?? false);
            }),
            if (isRented) ...[
              const Divider(),
              _buildTextField("Lessor's Full Name", _lessorName),
              _buildTextField("Lessor's Address", _lessorAddress),
              _buildTextField("Lessor's Tel/Mobile No.", _lessorContact, keyboardType: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly]),
              _buildTextField("Lessor's Email", _lessorEmail, keyboardType: TextInputType.emailAddress),
              _buildTextField("Monthly Rental", _monthlyRental, keyboardType: const TextInputType.numberWithOptions(decimal: true), formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
              const Divider(),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _goToNext,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
/// Screen 3: Business Activity
// -----------------------------------------------------------------------------
class Application3FormScreen extends StatefulWidget {
  final Map<String, dynamic> accumulatedData;
  const Application3FormScreen({super.key, required this.accumulatedData});

  @override
  State<Application3FormScreen> createState() => _Application3FormScreenState();
}

class _Application3FormScreenState extends State<Application3FormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLineOfBusiness;
  final TextEditingController _numOfUnits = TextEditingController();
  final TextEditingController _capitalization = TextEditingController();


  // final TextEditingController _lineOfBusiness = TextEditingController(text: "");
  // final TextEditingController _numOfUnits = TextEditingController();
  // final TextEditingController _capitalization = TextEditingController();
  
  bool _isSubmitting = false; 

  final List<String> _lineOfBusinessOptions = const [
    'General Business (Retail, Service, etc.)', // Covers businesses without special additional docs
    'Fishing Gears/Fish Pond',
    'Transport Operation'
  ];

  @override
  void dispose() {
    // _lineOfBusiness.dispose();
    _numOfUnits.dispose();
    _capitalization.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = true, bool isDecimal = false}) {
    TextInputType keyboardType = isNumber ? (isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number) : TextInputType.text;
    List<TextInputFormatter>? formatters = isDecimal 
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] 
        : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buidLineOfBusinessDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedLineOfBusiness,
        decoration: const InputDecoration(
          labelText: 'Line of Business',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select Business Type'),
        items: _lineOfBusinessOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedLineOfBusiness = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select the line of business';
          }
          return null;
        },
      ),
    );
  }

  void _goToReviewScreen() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form before proceeding.')),
      );
      return;
    }
    
    final Map<String, dynamic> finalData = {
      ...widget.accumulatedData,
      "line_of_business": _selectedLineOfBusiness,
      "num_of_units": int.tryParse(_numOfUnits.text.trim()) ?? 0,
      "capitalization": double.tryParse(_capitalization.text.trim())?.toString() ?? "0.0",

      "business_type": _selectedLineOfBusiness,
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(finalData: finalData)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Activity (3 of 3)'), backgroundColor: const Color(0xFF1A2B47)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("3. BUSINESS ACTIVITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            // _buildTextField("Line of Business", _lineOfBusiness),
            _buidLineOfBusinessDropdown(),
            
            _buildTextField("No. of Units", _numOfUnits, isNumber: true, isDecimal: false),
            
            _buildTextField("Capitalization (₱)", _capitalization, isNumber: true, isDecimal: true),
            
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : _goToReviewScreen,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                child: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                  : const Text('Review Application', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// // =============Old Codes===================================================================
// // application.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import '../api_services.dart';
// import 'review.dart';
// //
// // Screen 1 = ApplicationFormScreen
// // Screen 2 = Application2FormScreen
// // Screen 3 = Application3FormScreen (final submit)
// //

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

//   void _goToNext() {

//     if (!_formkey.currentState!.validate()) {
//       Scaffoldmessenger.of(content).showSnackBar(
//         const SnackBar(content: Text('Please correct the errors in the form before proceeding.')),
//       );
//       return;
//     }
//     // build partial data map from screen 1
//     final Map<String, dynamic> data = {
//       // top-level keys your backend currently expects for taxpayer + application
//       "first_name": _firstNameController.text.trim(),
//       "last_name": _lastNameController.text.trim(),
//       "middle_name": _middleNameController.text.trim(),
//       "trade_name": _tradeNameController.text.trim(),
//       "businessName": _businessNameController.text.trim(),
//       "account_number": _accountNumberController.text.trim(),
//       "tin_no": _tinController.text.trim(),
//       // application_type, mode_of_payment, business_type, amendment_from/ to
//       "application_type": isNewApplication ? "New Application" : (isRenewal ? "Renewal" : ""),
//       "mode_of_payment": isAnnually ? "Annually" : (isSemiAnnually ? "Semi-Annually" : (isQuarterly ? "Quarterly" : "")),
//       "business_type": isSingle ? "Single" : (isPartnership ? "Partnership" : (isCorporation ? "Corporation" : (isCooperative ? "Cooperative" : ""))),
//       "amendment_from": isFromSingle ? "Single" : (isFromPartnership ? "Partnership" : (isFromCorporation ? "Corporation" : "")),
//       "amendment_to": isToSingle ? "Single" : (isToPartnership ? "Partnership" : (isToCorporation ? "Corporation" : "")),
//       "has_tax_incentive": (hasTaxIncentive == true) ? 1 : 0,
//       "tax_incentive_entity": _entityController.text.trim(),
//       // application date as yyyy-mm-dd (if selected)
//       "application_date": selectedDate?.toIso8601String().split('T').first,
//     };

//     // if (!isNewApplication && !isRenewal) {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(content: Text('Please select either New Application or Renewal.')),
//     //   );
//     //   return;
//     // }

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => Application2FormScreen(initialData: data)),
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

//   @override
//   Widget build(BuildContext context) {
//     // UI kept intact, only changed Next to pass data
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
//             const Text("APPLICANT FORM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
//             const SizedBox(height: 16),
//             const Text("Basic Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),

//             _buildCheckboxRow(label: 'New Application', value: isNewApplication, onChanged: (v) {
//               setState(() {
//                 isNewApplication = v ?? false;
//                 if (isNewApplication) isRenewal = false;
//               });
//             }),
//             // _buildCheckboxRow(label: 'Renewal', value: isRenewal, onChanged: (v) {
//             //   setState(() {
//             //     isRenewal = v ?? false;
//             //     if (isRenewal) isNewApplication = false;
//             //   });
//             // }),
//             // const SizedBox(height: 16),

//             const Text("Mode of Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),
//             _buildCheckboxRow(label: 'Annually', value: isAnnually, onChanged: (v) {
//               setState(() {
//                 isAnnually = v ?? false;
//                 if (isAnnually) {
//                   isSemiAnnually = false;
//                   isQuarterly = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Semi-Annually', value: isSemiAnnually, onChanged: (v) {
//               setState(() {
//                 isSemiAnnually = v ?? false;
//                 if (isSemiAnnually) {
//                   isAnnually = false;
//                   isQuarterly = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Quarterly', value: isQuarterly, onChanged: (v) {
//               setState(() {
//                 isQuarterly = v ?? false;
//                 if (isQuarterly) {
//                   isAnnually = false;
//                   isSemiAnnually = false;
//                 }
//               });
//             }),
//             const SizedBox(height: 16),

//             const Text("Date of Application:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
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
//                 decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
//                 child: Text(selectedDate != null ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}" : 'Select a date'),
//               ),
//             ),
//             const SizedBox(height: 16),

//             TextField(controller: _tinController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'TIN No.:', border: OutlineInputBorder())),
//             const SizedBox(height: 16),

//             const Text("Type of Business", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),
//             _buildCheckboxRow(label: 'Single', value: isSingle, onChanged: (v) {
//               setState(() {
//                 isSingle = v ?? false;
//                 if (isSingle) {
//                   isPartnership = false;
//                   isCorporation = false;
//                   isCooperative = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Partnership', value: isPartnership, onChanged: (v) {
//               setState(() {
//                 isPartnership = v ?? false;
//                 if (isPartnership) {
//                   isSingle = false;
//                   isCorporation = false;
//                   isCooperative = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Corporation', value: isCorporation, onChanged: (v) {
//               setState(() {
//                 isCorporation = v ?? false;
//                 if (isCorporation) {
//                   isSingle = false;
//                   isPartnership = false;
//                   isCooperative = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Cooperative', value: isCooperative, onChanged: (v) {
//               setState(() {
//                 isCooperative = v ?? false;
//                 if (isCooperative) {
//                   isSingle = false;
//                   isPartnership = false;
//                   isCorporation = false;
//                 }
//               });
//             }),
//             const SizedBox(height: 16),

//             const Text("Amendment: From", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),
//             _buildCheckboxRow(label: 'Single', value: isFromSingle, onChanged: (v) {
//               setState(() {
//                 isFromSingle = v ?? false;
//                 if (isFromSingle) {
//                   isFromPartnership = false;
//                   isFromCorporation = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Partnership', value: isFromPartnership, onChanged: (v) {
//               setState(() {
//                 isFromPartnership = v ?? false;
//                 if (isFromPartnership) {
//                   isFromSingle = false;
//                   isFromCorporation = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Corporation', value: isFromCorporation, onChanged: (v) {
//               setState(() {
//                 isFromCorporation = v ?? false;
//                 if (isFromCorporation) {
//                   isFromSingle = false;
//                   isFromPartnership = false;
//                 }
//               });
//             }),
//             const SizedBox(height: 16),

//             const Text("To", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),
//             _buildCheckboxRow(label: 'Single', value: isToSingle, onChanged: (v) {
//               setState(() {
//                 isToSingle = v ?? false;
//                 if (isToSingle) {
//                   isToPartnership = false;
//                   isToCorporation = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Partnership', value: isToPartnership, onChanged: (v) {
//               setState(() {
//                 isToPartnership = v ?? false;
//                 if (isToPartnership) {
//                   isToSingle = false;
//                   isToCorporation = false;
//                 }
//               });
//             }),
//             _buildCheckboxRow(label: 'Corporation', value: isToCorporation, onChanged: (v) {
//               setState(() {
//                 isToCorporation = v ?? false;
//                 if (isToCorporation) {
//                   isToSingle = false;
//                   isToPartnership = false;
//                 }
//               });
//             }),
//             const SizedBox(height: 16),

//             const Text("Are you enjoying tax incentive from any Government entity?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 8),
//               Row(children: [
//               Radio<bool>(value: true, groupValue: hasTaxIncentive, onChanged: (bool? value) {
//               setState(() {
//               hasTaxIncentive = value;
//                   });
//                  }),
//             const Text('Yes'),
//             const SizedBox(width: 24),
//                Radio<bool>(value: false, groupValue: hasTaxIncentive, onChanged: (bool? value) {
//                setState(() {
//             hasTaxIncentive = value;
//             // ⭐ FIX: Clear the controller when 'No' is selected
//             if (value == false) {
//                 _entityController.clear(); 
//                }
//               });
//               }),
//               const Text('No'),
//                   ]),
//             const SizedBox(height: 8),
//                   if (hasTaxIncentive == true)
//                    TextField(controller: _entityController, decoration: const InputDecoration(labelText: 'Please Specify the Entity', border: OutlineInputBorder())),
//             const SizedBox(height: 16),

//             const Text("Name of the Taxpayer/Registrant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
//             const SizedBox(height: 16),
//             TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
//             const SizedBox(height: 12),
//             TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
//             const SizedBox(height: 12),
//             TextField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name', border: OutlineInputBorder())),
//             const SizedBox(height: 12),
//             TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
//             const SizedBox(height: 12),
//             TextField(controller: _accountNumberController, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder())),
//             const SizedBox(height: 12),
//             TextField(controller: _tradeNameController, decoration: const InputDecoration(labelText: 'Trade Name/Franchise', border: OutlineInputBorder())),
//             const SizedBox(height: 24),

//             Center(
//               child: ElevatedButton(
//                 onPressed: _goToNext,
//                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
//                 child: const Text('Next', style: TextStyle(fontSize: 16, color: (Colors.white))),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Screen 2
// class Application2FormScreen extends StatefulWidget {
//   final Map<String, dynamic> initialData;
//   const Application2FormScreen({super.key, required this.initialData});

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
//   void dispose() {
//     _businessAddress.dispose();
//     _postalCode.dispose();
//     _ownerAddress.dispose();
//     _ownerEmail.dispose();
//     _ownerMobile.dispose();
//     _emergencyContact.dispose();
//     _emergencyEmail.dispose();
//     _emergencyMobile.dispose();
//     _businessArea.dispose();
//     _employeesTotal.dispose();
//     _employeesWithLGU.dispose();
//     _lessorName.dispose();
//     _lessorAddress.dispose();
//     _lessorContact.dispose();
//     _lessorEmail.dispose();
//     _monthlyRental.dispose();
//     super.dispose();
//   }

//   Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         validator: (value) => null,
//         decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
//       ),
//     );
//   }

//   void _goToNext() {
//     // merge initialData (from screen1) with screen2 values
//     final merged = {
//       ...widget.initialData,
//       // application detail keys expected by DB (top-level in current Flask)
//       "business_address": _businessAddress.text.trim(),
//       "postal_code": _postalCode.text.trim(),
//       "owner_address": _ownerAddress.text.trim(),
//       "owner_email": _ownerEmail.text.trim(),
//       "owner_mobile": _ownerMobile.text.trim(),
//       "emergency_contact": _emergencyContact.text.trim(),
//       "emergency_email": _emergencyEmail.text.trim(),
//       "emergency_mobile": _emergencyMobile.text.trim(),
//       "business_area": _businessArea.text.trim(),
//       "employees_total": _employeesTotal.text.trim(),
//       "employees_with_lgu": _employeesWithLGU.text.trim(),
//       "is_rented": isRented ? 1 : 0,
//       // lessor fields
//       "lessor_name": _lessorName.text.trim(),
//       "lessor_address": _lessorAddress.text.trim(),
//       "lessor_email": _lessorEmail.text.trim(),
//       "lessor_mobile": _lessorContact.text.trim(),
//       "monthly_rent": _monthlyRental.text.trim(),
//     };

//     Navigator.push(context, MaterialPageRoute(builder: (_) => Application3FormScreen(accumulatedData: merged)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Application Form'), backgroundColor: const Color(0xFF1A2B47)),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Text("2. OTHER INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const Text("Note: For RENEWAL APPLICATIONS, do not fill up this section unless information have changed ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
//             const SizedBox(height: 10),
//             _buildTextField("Business Address", _businessAddress),
//             _buildTextField("Postal Code", _postalCode),
//             _buildTextField("Owner's Address", _ownerAddress),
//             _buildTextField("Email Address", _ownerEmail),
//             _buildTextField("Mobile No.", _ownerMobile),
//             _buildTextField("Emergency Contact Person", _emergencyContact),
//             _buildTextField("Emergency Email", _emergencyEmail),
//             _buildTextField("Emergency Mobile No.", _emergencyMobile),
//             _buildTextField("Business Area (in sq. m.)", _businessArea),
//             _buildTextField("Total No. of Employees", _employeesTotal),
//             _buildTextField("No. of Employees Residing with LGU", _employeesWithLGU),

//             const SizedBox(height: 12),
//             CheckboxListTile(title: const Text("Business Place is Rented"), value: isRented, onChanged: (value) {
//               setState(() => isRented = value ?? false);
//             }),
//             if (isRented) ...[
//               _buildTextField("Lessor's Full Name", _lessorName),
//               _buildTextField("Lessor's Address", _lessorAddress),
//               _buildTextField("Lessor's Tel/Mobile No.", _lessorContact),
//               _buildTextField("Lessor's Email", _lessorEmail),
//               _buildTextField("Monthly Rental", _monthlyRental),
//             ],

//             const SizedBox(height: 24),
//             Center(
//               child: ElevatedButton(
//                 onPressed: _goToNext,
//                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
//                 child: const Text('Next', style: TextStyle(fontSize: 16)),
//               ),
//             ),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// class Application3FormScreen extends StatefulWidget {
//   final Map<String, dynamic> accumulatedData;
//   const Application3FormScreen({super.key, required this.accumulatedData});

//   @override
//   State<Application3FormScreen> createState() => _Application3FormScreenState();
// }

// class _Application3FormScreenState extends State<Application3FormScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _lineOfBusiness = TextEditingController(text: "");
//   final TextEditingController _numOfUnits = TextEditingController();
//   final TextEditingController _capitalization = TextEditingController();
//   // final TextEditingController _grossSalesEssential = TextEditingController();
//   // final TextEditingController _grossSalesNonEssential = TextEditingController();

//   // Changed to non-final state variable (used for loading in the old flow, retained here)
//   bool _isSubmitting = false; 

//   @override
//   void dispose() {
//     _lineOfBusiness.dispose();
//     _numOfUnits.dispose();
//     _capitalization.dispose();
//     // _grossSalesEssential.dispose();
//     // _grossSalesNonEssential.dispose();
//     super.dispose();
//   }

//   // 🛑 NEW NAVIGATION METHOD: Sends data to Review Screen 🛑
//   void _goToReviewScreen() {
//     if (!_formKey.currentState!.validate()) return;
    
//     // Build final map, merging Screen 3 data with previous data
//     final Map<String, dynamic> finalData = {
//       // merge existing accumulatedData (from screens 1 & 2)
//       ...widget.accumulatedData,
//       "application_date": widget.accumulatedData["application_date"] ?? DateTime.now().toIso8601String().split('T').first,
      
//       // Screen 3 data: Business Activity
//       "line_of_business": _lineOfBusiness.text.trim(),
//       "num_of_units": int.tryParse(_numOfUnits.text.trim()) ?? 0,
//       "capitalization": double.tryParse(_capitalization.text.trim())?.toString() ?? "0.0",
//       // "gross_sales_essential": double.tryParse(_grossSalesEssential.text.trim())?.toString() ?? "0.0",
//       // "gross_sales_non_essential": double.tryParse(_grossSalesNonEssential.text.trim())?.toString() ?? "0.0",
//     };

//     // Navigate to the Review Screen (Screen 4)
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => ReviewScreen(finalData: finalData)),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         validator: (value) => value == null || value.isEmpty ? 'Required' : null,
//         decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Business Activity'), backgroundColor: const Color(0xFF1A2B47)),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             const Text("3. BUSINESS ACTIVITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 10),
//             _buildTextField("Line of Business", _lineOfBusiness),
//             _buildTextField("No. of Units", _numOfUnits, isNumber: true),
//             _buildTextField("Capitalization (₱)", _capitalization, isNumber: true),
//             // _buildTextField("Gross/Sales Receipts (Essential)", _grossSalesEssential, isNumber: true),
//             // _buildTextField("Gross/Sales Receipts (Non-Essential)", _grossSalesNonEssential, isNumber: true),
//             const SizedBox(height: 24),
//             Center(
//               child: ElevatedButton(
//                 // 🛑 BUTTON NOW CALLS THE NAVIGATION TO REVIEW SCREEN 🛑
//                 onPressed: _isSubmitting
//                     ? null
//                     : () {
//                         if (_formKey.currentState!.validate()) {
//                           _goToReviewScreen(); // Navigate to the review screen
//                         }
//                       },
//                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B47), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
//                 child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Review Application', style: TextStyle(fontSize: 16, color: Colors.white)),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ]),
//         ),
//       ),
//     );
//   }
// }

