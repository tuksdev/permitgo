import 'dart:async';
import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // For picking images/files

// NOTE: We assume ApiService and ImageAnalysisService are available
import '../api_service.dart';
// Assuming a placeholder class for the blur check to compile the code
class ImageAnalysisService {
  static Future<bool> isImageBlurry(File file) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulated blur check: always returns false for simplicity
    return false;
  }
}

// --- 1. REAL API CALL FOR FETCHING LAST APPLICATION FOR RENEWAL ---
Future<Map<String, dynamic>?> fetchLastApplicationForRenewal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString();

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final result = await ApiService.fetchApplicationDetailsForRenewal(userId);

    if (result['success'] == true) {
      return result['data'];
    } else {
      // Return null if no previous application found
      return null;
    }
  } catch (e) {
    throw Exception('Failed to fetch renewal data: $e');
  }
}

// --- 2. APPLICATION ENTRY SCREEN RENAMED TO RENEWALSCREEN ---
class RenewalScreen extends StatefulWidget {
  final Map<String, dynamic>? existingApplication; // Add this parameter

  const RenewalScreen({
    super.key,
    this.existingApplication, // Add this parameter
  });

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  Map<String, dynamic>? _renewalData;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchRenewalData();
  }

  Future<void> _fetchRenewalData() async {
    try {
      // If existingApplication is passed, use it directly
      if (widget.existingApplication != null) {
        setState(() {
          _renewalData = widget.existingApplication;
          _isFetching = false;
        });
        return;
      }
      
      // Otherwise, fetch from API as before
      final data = await fetchLastApplicationForRenewal();
      setState(() {
        _renewalData = data;
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _isFetching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching previous data: $e")));
    }
  }

  void _startApplication({required bool isRenewal}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationFormScreen1(
          existingData: isRenewal ? _renewalData : null,
          isRenewalMode: isRenewal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        title: const Text('Permit Application Hub', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Start Your Permit Application",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // --- New Application Button ---
              ElevatedButton.icon(
                onPressed: () => _startApplication(isRenewal: false),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Start New Application"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 20),

              // --- Renewal Section ---
              _isFetching
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _renewalData != null
                          ? () => _startApplication(isRenewal: true)
                          : null,
                      icon: const Icon(Icons.autorenew),
                      label: const Text("Renew Existing Permit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
              
              const SizedBox(height: 10),
              Text(
                _renewalData != null 
                    ? "Tap to renew ${_renewalData!['businessName'] ?? _renewalData!['trade_name'] ?? 'your business'}." 
                    : "Renewal unavailable: No prior application found.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              
              const SizedBox(height: 40),

              // --- Document Requirements Button (Navigates to Checklist) ---
              OutlinedButton.icon(
                onPressed: () {
                  final appId = _renewalData?['application_id']?.toString() ?? 
                               _renewalData?['id']?.toString() ?? 'NEW';
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DocumentChecklistScreen(applicationId: appId)),
                  );
                },
                icon: const Icon(Icons.checklist),
                label: const Text("View Documentary Requirements"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. DOCUMENT CHECKLIST SCREEN (Updated to pass Application ID) ---
class DocumentChecklistScreen extends StatefulWidget {
  final String applicationId;

  const DocumentChecklistScreen({super.key, required this.applicationId});

  @override
  State<DocumentChecklistScreen> createState() => _DocumentChecklistScreenState();
}

class _DocumentChecklistScreenState extends State<DocumentChecklistScreen> {
  final Map<String, bool> documentStatus = {
    "Community Tax Certificate (Cedula)": false,
    "Barangay Clearance": false,
    "Barangay Business Permit": false,
    "DTI Certification / SEC": false,
    "Landholdings Certificate": false,
    "Fire Safety Inspection Certificate": false,
    "Sanitary Permit/Health Certificate": false,
    "ITR or BIR Form 1701/1702": false,
    // Add conditional requirements if needed
  };

  void markAsApproved(String doc) {
    setState(() {
      documentStatus[doc] = true;
    });
  }
  
  void _goToUpload(String docName) async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the actual application ID and document name
        builder: (_) => UploadDocumentPage(
          applicationId: widget.applicationId, 
          documentName: docName,
        ),
      ),
    );
    if (success == true) {
      markAsApproved(docName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B47),
        title: const Text('Documentary Requirements', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Required Documents for Application ID: ${widget.applicationId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          ...documentStatus.entries.map((entry) {
            final doc = entry.key;
            final approved = entry.value;
            return ListTile(
              title: Text(
                doc,
                style: TextStyle(
                  color: approved ? Colors.green[700] : Colors.black,
                  decoration: approved ? TextDecoration.lineThrough : TextDecoration.none,
                  fontWeight: approved ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: approved
                  ? Icon(Icons.check_circle, color: Colors.green[700])
                  : const Icon(Icons.cloud_upload, color: Colors.blue),
              onTap: approved ? null : () => _goToUpload(doc),
            );
          }).toList(),
          const SizedBox(height: 20),
          const Text("Note: After securing the physical documents (Steps 1-6 of the process), you must upload them here to proceed to the online form filling (Step 7 onwards).", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- 4. UPLOAD DOCUMENT PAGE (Functionalized) ---
class UploadDocumentPage extends StatefulWidget {
  final String applicationId;
  final String documentName;

  const UploadDocumentPage({
    super.key, 
    required this.applicationId, 
    required this.documentName,
  });

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  File? _selectedFile;
  final picker = ImagePicker();
  bool isLoading = false;
  
  // FIX 1: Make _message late
  late String _message; 

  @override
  void initState() {
    super.initState();
    // FIX 2: Initialize _message here using widget property
    _message = "Select the file for: ${widget.documentName}"; 
  }

  Future<void> _pickFile() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final selectedFile = File(pickedFile.path);
      setState(() {
        isLoading = true;
        _message = "Analyzing image quality...";
      });

      // NOTE: Placeholder call structure
      final isBlurry = await ImageAnalysisService.isImageBlurry(selectedFile);

      setState(() {
        isLoading = false;
        if (isBlurry) {
          _selectedFile = null;
          _message = "⚠️ Image is too blurry. Please capture or choose a clearer document.";
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image quality check failed.'), backgroundColor: Colors.red),
          );
        } else {
          _selectedFile = selectedFile;
          _message = "File selected: ${selectedFile.path.split('/').last}";
        }
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      _message = "Uploading ${widget.documentName} for ID ${widget.applicationId}...";
    });
    
    // --- ACTUAL UPLOAD LOGIC (Calling ApiService) ---
    final Map<String, dynamic> result = await ApiService.uploadDocument(
      applicationId: widget.applicationId,
      documentName: widget.documentName, // Pass directly from widget property
      file: _selectedFile!,
    );
    // ------------------------------------------

    setState(() {
      isLoading = false;
      final success = result['status'] == 'success';
      _message = result['message']?.toString() ?? (success ? 'Upload completed successfully.' : 'Upload failed.');
      
      if (success) {
        _selectedFile = null;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message), backgroundColor: success ? Colors.green : Colors.red),
      );
    });
    
    // Return 'true' to the Checklist screen on success
    if (result['status'] == 'success') {
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload: ${widget.documentName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_message, 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedFile == null ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(height: 20),

            // Document Name Display (Read-only as it's passed in)
            TextField(
              controller: TextEditingController(text: widget.documentName), // Use a temporary controller to display the passed value
              readOnly: true, 
              decoration: const InputDecoration(
                labelText: "Document Name (Required)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // File Preview or Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50
              ),
              alignment: Alignment.center,
              child: _selectedFile == null
                  ? const Text("No file selected", style: TextStyle(color: Colors.grey))
                  : Image.file(
                      _selectedFile!, 
                      height: 200, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 30),

            // Choose File Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _pickFile,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text("Select Document Photo"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Upload Button
            ElevatedButton(
              onPressed: (_selectedFile == null || isLoading) ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Finalize Upload"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. APPLICATION FORM SCREEN (STEP 1) ---
typedef ExistingTaxpayerData = Map<String, dynamic>;

class ApplicationFormScreen1 extends StatefulWidget {
  final ExistingTaxpayerData? existingData;
  final bool isRenewalMode; 

  const ApplicationFormScreen1({
    super.key, 
    this.existingData,
    this.isRenewalMode = false,
  });

  @override
  _ApplicationFormScreenState1 createState() => _ApplicationFormScreenState1();
}

class _ApplicationFormScreenState1 extends State<ApplicationFormScreen1> {
  late bool isNewApplication;
  late bool isRenewal;

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
  void initState() {
    super.initState();
    final data = widget.existingData;
    final isRenewing = widget.isRenewalMode && data != null;

    isNewApplication = !isRenewing;
    isRenewal = isRenewing;

    if (isRenewing) {
      // --- SCREEN 1 PRE-FILL LOGIC ---
      // Pre-fill controllers (Taxpayer/Business Name/Account)
      _lastNameController.text = data!['last_name'] ?? '';
      _firstNameController.text = data['first_name'] ?? '';
      _middleNameController.text = data['middle_name'] ?? '';
      _businessNameController.text = data['businessName'] ?? '';
      _accountNumberController.text = data['account_number'] ?? '';
      _tradeNameController.text = data['trade_name'] ?? '';
      
      // Pre-fill TIN No.
      _tinController.text = data['tin_no'] ?? '';
      
      // Pre-fill Tax Incentive
      _entityController.text = data['tax_incentive_entity'] ?? '';
      hasTaxIncentive = data['has_tax_incentive'] == 1 || data['has_tax_incentive'] == true;

      // Date of Application: BLANK as requested (Default state of selectedDate = null handles this)
      selectedDate = null; 

      // Set Checkboxes (Type of Business & Mode of Payment)
      _setCheckboxState(data['business_type']?.toString(), 'business_type');
      _setCheckboxState(data['mode_of_payment']?.toString(), 'mode_of_payment');
      
      // Amendment fields should remain BLANK for renewal unless they are changing it now.
    } else {
      selectedDate = null; 
    }
  }

  void _setCheckboxState(String? value, String type) {
    if (value == null) return;
    
    setState(() {
      if (type == 'business_type') {
        isSingle = value == 'Single';
        isPartnership = value == 'Partnership';
        isCorporation = value == 'Corporation';
        isCooperative = value == 'Cooperative';
      } else if (type == 'mode_of_payment') {
        isAnnually = value == 'Annually';
        isSemiAnnually = value == 'Semi-Annually';
        isQuarterly = value == 'Quarterly';
      }
    });
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
    if (!isNewApplication && !isRenewal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Application Type (New or Renewal).')));
      return;
    }
    
    final Map<String, dynamic> data = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "middle_name": _middleNameController.text.trim(),
      "trade_name": _tradeNameController.text.trim(),
      "businessName": _businessNameController.text.trim(),
      "account_number": _accountNumberController.text.trim(),
      "tin_no": _tinController.text.trim(),
      "application_type": isNewApplication ? "New Application" : (isRenewal ? "Renewal" : ""), 
      "mode_of_payment": isAnnually ? "Annually" : (isSemiAnnually ? "Semi-Annually" : (isQuarterly ? "Quarterly" : "")),
      "business_type": isSingle ? "Single" : (isPartnership ? "Partnership" : (isCorporation ? "Corporation" : (isCooperative ? "Cooperative" : ""))),
      "amendment_from": isFromSingle ? "Single" : (isFromPartnership ? "Partnership" : (isFromCorporation ? "Corporation" : "")),
      "amendment_to": isToSingle ? "Single" : (isToPartnership ? "Partnership" : (isToCorporation ? "Corporation" : "")),
      "has_tax_incentive": (hasTaxIncentive == true) ? 1 : 0,
      "tax_incentive_entity": _entityController.text.trim(),
      "application_date": selectedDate?.toIso8601String().split('T').first,
      ...widget.existingData ?? {},
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${isRenewal ? "Renewal" : "New"} Application Form', style: const TextStyle(color: Colors.white)),
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

            // Application Type Section
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

// --- 5. APPLICATION FORM SCREEN (STEP 2) ---
class Application2FormScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const Application2FormScreen({super.key, required this.initialData});

  @override
  State<Application2FormScreen> createState() => _Application2FormScreenState();
}

class _Application2FormScreenState extends State<Application2FormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessAddress;
  late final TextEditingController _postalCode;
  late final TextEditingController _ownerAddress;
  late final TextEditingController _ownerEmail;
  late final TextEditingController _ownerMobile;
  late final TextEditingController _emergencyContact;
  late final TextEditingController _emergencyEmail;
  late final TextEditingController _emergencyMobile;
  late final TextEditingController _businessArea;
  late final TextEditingController _employeesTotal;
  late final TextEditingController _employeesWithLGU;

  late bool isRented;

  late final TextEditingController _lessorName;
  late final TextEditingController _lessorAddress;
  late final TextEditingController _lessorContact;
  late final TextEditingController _lessorEmail;
  late final TextEditingController _monthlyRental;

  @override
  void initState() {
    super.initState();
    final isRenewal = widget.initialData['application_type'] == 'Renewal';
    final data = widget.initialData;

    // Helper function to safely get text. It always returns the fetched value for renewal.
    String initialText(String key) {
      if (!isRenewal) return '';
      return data[key]?.toString() ?? ''; 
    }

    // --- SCREEN 2 PRE-FILL LOGIC: ALL FIELDS PRE-FILLED FOR RENEWAL ---
    _businessAddress = TextEditingController(text: initialText('business_address'));
    _postalCode = TextEditingController(text: initialText('postal_code'));
    _ownerAddress = TextEditingController(text: initialText('owner_address'));
    _ownerEmail = TextEditingController(text: initialText('owner_email'));
    _ownerMobile = TextEditingController(text: initialText('owner_mobile'));
    _emergencyContact = TextEditingController(text: initialText('emergency_contact'));
    _emergencyEmail = TextEditingController(text: initialText('emergency_email'));
    _emergencyMobile = TextEditingController(text: initialText('emergency_mobile'));
    _businessArea = TextEditingController(text: initialText('business_area'));
    _employeesTotal = TextEditingController(text: initialText('employees_total'));
    _employeesWithLGU = TextEditingController(text: initialText('employees_with_lgu'));

    // Set rental status
    isRented = isRenewal ? (data['is_rented'] == 1 || data['is_rented'] == 'Rented') : false;

    // Initialize Lessor controllers (Pre-fill if isRented is true)
    _lessorName = TextEditingController(text: isRented ? initialText('lessor_name') : '');
    _lessorAddress = TextEditingController(text: isRented ? initialText('lessor_address') : '');
    _lessorContact = TextEditingController(text: isRented ? initialText('lessor_mobile') : '');
    _lessorEmail = TextEditingController(text: isRented ? initialText('lessor_email') : '');
    _monthlyRental = TextEditingController(text: isRented ? initialText('monthly_rent') : '');
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
    final merged = {
      ...widget.initialData,
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
      "lessor_name": isRented ? _lessorName.text.trim() : '',
      "lessor_address": isRented ? _lessorAddress.text.trim() : '',
      "lessor_email": isRented ? _lessorEmail.text.trim() : '',
      "lessor_mobile": isRented ? _lessorContact.text.trim() : '',
      "monthly_rent": isRented ? _monthlyRental.text.trim() : '',
    };

    Navigator.push(context, MaterialPageRoute(builder: (_) => Application3FormScreen(accumulatedData: merged)));
  }

  @override
  Widget build(BuildContext context) {
    final isRenewal = widget.initialData['application_type'] == 'Renewal';

    return Scaffold(
      appBar: AppBar(title: const Text('Other Information'), backgroundColor: const Color(0xFF1A2B47)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("2. OTHER INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (isRenewal)
              const Text("Note: For RENEWAL APPLICATIONS, review the pre-filled information below and update only if changes occurred.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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
              setState(() {
                isRented = value ?? false;
                if (!isRented) {
                   _lessorName.clear();
                   _lessorAddress.clear();
                   _lessorContact.clear();
                   _lessorEmail.clear();
                   _monthlyRental.clear();
                }
              });
            }),
            if (isRented) ...[
              const SizedBox(height: 10),
              const Text("Lessor Details (Required for Rented Business Place)", style: TextStyle(fontWeight: FontWeight.w500)),
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
                child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


// --- 6. APPLICATION FORM SCREEN (STEP 3) ---
class Application3FormScreen extends StatefulWidget {
  final Map<String, dynamic> accumulatedData;
  const Application3FormScreen({super.key, required this.accumulatedData});

  @override
  State<Application3FormScreen> createState() => _Application3FormScreenState();
}

class _Application3FormScreenState extends State<Application3FormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lineOfBusiness;
  late final TextEditingController _numOfUnits;
  late final TextEditingController _capitalization;
  late final TextEditingController _grossSalesEssential;
  late final TextEditingController _grossSalesNonEssential;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final isRenewal = widget.accumulatedData['application_type'] == 'Renewal';
    final data = widget.accumulatedData;

    String initialText(String key) {
      if (!isRenewal) return '';
      return data[key]?.toString() ?? ''; 
    }

    // --- SCREEN 3 PRE-FILL LOGIC: ALL FIELDS PRE-FILLED FOR RENEWAL ---
    _lineOfBusiness = TextEditingController(text: initialText('line_of_business'));
    _numOfUnits = TextEditingController(text: initialText('num_of_units'));
    _capitalization = TextEditingController(text: initialText('capitalization'));
    _grossSalesEssential = TextEditingController(text: initialText('gross_sales_essential'));
    _grossSalesNonEssential = TextEditingController(text: initialText('gross_sales_non_essential'));
    
    // Fallback: If capitalization was aggregated in mock data fetching, use that.
    if (_capitalization.text.isEmpty && isRenewal) {
        _capitalization.text = data['total_capitalization']?.toString() ?? '';
    }
  }

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

    final Map<String, dynamic> finalData = {
      "user_id": userIdStr,
      ...widget.accumulatedData,
      "application_date": widget.accumulatedData["application_date"] ?? DateTime.now().toIso8601String().split('T').first,
      "line_of_business": _lineOfBusiness.text.trim(),
      "num_of_units": int.tryParse(_numOfUnits.text.trim()) ?? 0,
      "capitalization": double.tryParse(_capitalization.text.trim())?.toString() ?? "0.0",
      "gross_sales_essential": double.tryParse(_grossSalesEssential.text.trim())?.toString() ?? "0.0",
      "gross_sales_non_essential": double.tryParse(_grossSalesNonEssential.text.trim())?.toString() ?? "0.0",
    };

    print("==== Submitting application payload ====");
    print(finalData);

    try {
      // final result = await ApiService.submitApplication(finalData); // RESTORE this when ApiService is complete
      // *** MOCK SUBMIT ***
      await Future.delayed(const Duration(seconds: 1));
      final result = {"status": "success", "message": "Simulated submit successful"};
      // *** END MOCK ***

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
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

