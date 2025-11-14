import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl = "http://192.168.100.203:5000"; 
  static const Duration _timeoutDuration = Duration(seconds: 10);

static Future<Map<String, dynamic>> getPendingApplication(String userId) async {
  final url = Uri.parse('$baseUrl/get_pending_application?user_id=$userId');

  try {
    // CRITICAL FIX: Add timeout here
    final response = await http.get(url).timeout(_timeoutDuration);

    if (response.statusCode == 200 || response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      return {"success": false, "message": "Failed to fetch application data. Status: ${response.statusCode}"};
    }
  } on TimeoutException {
    return {"success": false, "message": "Network timeout: Initial ID fetch failed."};
  } on SocketException {
    return {"success": false, "message": "Network error: Server is unreachable at $baseUrl"};
  } catch (e) {
    return {"success": false, "message": "Exception during ID fetch: ${e.toString()}"};
  }
}

  static Future<Map<String, dynamic>> getApplicationPaymentDetails(String userId) async {
  const String url = '$baseUrl/api/user/application_payment_details'; 
  
  try {
    final uri = Uri.parse('$url?user_id=$userId');
    // CRITICAL: Apply timeout here
    final response = await http.get(uri).timeout(_timeoutDuration); 

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        return {
          'success': true,
          'application_id': data['application_id'].toString(),
          'business_name': data['businessName'], 
          'status_detail': data['status_detail'], 
          'due_date': data['due_date'],           
          'payment_date': data['payment_date'],   
        };
      }
      return {'success': false, 'message': data['message'] ?? 'No active application found.'};
    } 
    
    final errorBody = json.decode(response.body);
    return {'success': false, 'message': errorBody['message'] ?? 'Server error on status fetch (HTTP ${response.statusCode}).'};
    
  } on TimeoutException {
    return {'success': false, 'message': 'Network timeout: Status details fetch failed.'};
  } on SocketException {
    return {'success': false, 'message': 'Network error: Server is unreachable at $baseUrl'};
  } catch (e) {
    return {'success': false, 'message': 'Exception during status fetch: $e'};
  }
  }
  // ---------- Signup ----------
  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    final url = Uri.parse('$baseUrl/signup');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "first_name": firstName,
        "last_name": lastName,
        "middle_name": middleName ?? "",
        "email": email,
        "password": password,
        "mobile_number": mobileNumber,
      }),
    );
    //return jsonDecode(response.body);

    if (response.statusCode ==200) {
      return jsonDecode(response.body);
    } else {
     return {"status": "error", "message": "Sign Ip failed"};
    }
  }

  // ---------- Signin ----------
  static Future<Map<String, dynamic>> signin({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/signin');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

      // ✅ Get the nested user object properly
        if (data["status"] == "success" && data["user"] != null) {
          return {
            "status": "success",
            "message": data["message"] ?? "Login successful",
            "user": data["user"], // includes user_id, email, etc.
          };
        } else {
          return {
            "status": "error",
            "message": data["message"] ?? "Invalid credentials"
          };
        }
      } else {
        return {
          "status": "error",
          "message": "Invalid credentials or server issue"
        };
     }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/get_user_profile/$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        return {'status': 'error', 'message': body['message'] ?? 'Server responded with error ${response.statusCode}'};
      }
    } catch (e) {
      print('Error during profile fetch: $e');
      return {'status': 'error', 'message': 'Network error. Please check server connection.'};
    }
  }


  // 🛑 submitApplication - FIX APPLIED 🛑
  static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/submit_application');
    // print("📤 Sending data to backend: ${jsonEncode(data)}"); // Removed print warning

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final responseBody = jsonDecode(response.body);
      // print("📥 Response: ${response.body}"); // Removed print warning

      // Checks for 201 Created status code from the backend
      if (response.statusCode == 201) { 
        return responseBody;
      } else {
        return {
          "status": "error",
          "message": responseBody["message"] ?? responseBody["error"] ?? "Submission failed. Status: ${response.statusCode}"
        };
      }
    } on SocketException {
      return {"status": "error", "message": "Network connection error. Server connection refused."};
    } catch (e) {
      return {"status": "error", "message": "An unexpected error occurred: ${e.toString()}"};
    }
  }

  // 🛑 uploadDocument - FIX APPLIED (Removed redundant lines) 🛑
  // api_services.dart (Add this new function)

  static Future<Map<String, dynamic>> fetchRequirements(String documentPurpose) async {
    final url = Uri.parse('$baseUrl/get_requirements/$documentPurpose'); 
    
    try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            // Assuming Flask returns {"status": "success", "requirements": [...]}
            return {"status": "success", "requirements": responseData["requirements"]}; 
        } else {
            return {"status": "error", "message": "Failed to fetch requirements list: ${response.statusCode}"};
        }
    } on SocketException {
        return {"status": "error", "message": "Network connection error. Server is unreachable."};
    } catch (e) {
        return {"status": "error", "message": "Exception: ${e.toString()}"};
    }
  }


  // CRITICAL FIX: This is the method definition that was missing or incorrect
  static Future<Map<String, dynamic>> uploadDocument({
    required String applicationId,
    required String documentName,
    required File file,
    required String documentPurpose,
  }) async {
    final url = Uri.parse('$baseUrl/upload_document'); 
    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['application_id'] = applicationId;
      request.fields['document_name'] = documentName; 
      request.fields['document_purpose'] = documentPurpose; 

      request.files.add(await http.MultipartFile.fromPath(
          'document', // This MUST match the key Flask looks for (request.files['document'])
          file.path,
          filename: file.path.split('/').last,
      ));

      var responseStreamed = await request.send();
      final response = await http.Response.fromStream(responseStreamed);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"status": "success", "message": responseData["message"]};
      } else {
        return {"status": "error", "message": responseData["message"] ?? "Upload failed: ${response.statusCode}"};
      }
    } on SocketException {
      return {"status": "error", "message": "Network connection error. Server is unreachable."};
    } catch (e) {
      return {"status": "error", "message": "Exception during upload: ${e.toString()}"};
    }
  }
  // static Future<Map<String, dynamic>> uploadDocument({
  //     required String applicationId,
  //     required String documentName,
  //     required File file,
  //     required String documentPurpose,
  // }) async {
  //   final url = Uri.parse('$baseUrl/upload_document'); 
  //   try {
  //     var request = http.MultipartRequest('POST', url);

  //     request.fields['application_id'] = applicationId;
  //     request.fields['document_name'] = documentName; 
  //     request.fields['document_purpose'] = documentPurpose; 

  //     request.files.add(await http.MultipartFile.fromPath(
  //         'document', 
  //         file.path,
  //         filename: file.path.split('/').last,
  //     ));

  //     var responseStreamed = await request.send();
  //     final response = await http.Response.fromStream(responseStreamed);

  //     final responseData = jsonDecode(response.body);

  //     if (response.statusCode == 200) {
  //       return {"status": "success", "message": responseData["message"]};
  //     } else {
  //       return {"status": "error", "message": responseData["message"] ?? "Upload failed: ${response.statusCode}"};
  //     }
  //   } on SocketException {
  //     return {"status": "error", "message": "Network connection error. Server is unreachable."};
  //   } catch (e) {
  //     return {"status": "error", "message": "Exception during upload: ${e.toString()}"};
  //   }
  // }

  // ... (All other ApiService methods like signin, signup, fetchApprovedBusinesses, etc., 
  // need to be retained in this file, though their fixes are not shown here for brevity) ...

  // // ---------- Submit Application ----------
  // static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
  //   final url = Uri.parse('$baseUrl/submit_application');
  //   print("📤 Sending data to backend: ${jsonEncode(data)}"); // debug log

  //   final response = await http.post(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );

  //   print("📥 Response: ${response.body}"); // debug log
  //   return jsonDecode(response.body);
  // }

  // ---------- Forgot Password ----------
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/forgot_password');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Handle non-200 responses gracefully
        final errorData = jsonDecode(response.body);
        return {
          "status": "error", 
          "message": errorData["message"] ?? "Server error occurred. Status code: ${response.statusCode}"
        };
      }
    } on SocketException {
      return {"status": "error", "message": "No internet connection."};
    } catch (e) {
      return {"status": "error", "message": "An unexpected error occurred: ${e.toString()}"};
    }
  }
  
  // ========================================================
// 🛑 CORE RENEWAL & DOCUMENT FUNCTIONS 🛑
// ========================================================

/// 1. Fetches approved businesses, filtered by user ID, including all pre-fill data.
static Future<List<dynamic>> fetchApprovedBusinesses({required String userId}) async {
    // Correctly forms the URL with the userId parameter for backend filtering
    final url = Uri.parse('$baseUrl/api/approved_businesses?user_id=$userId');
    try {
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            // Returns the list containing address, contact, and business activity details
            return data['businesses'] ?? []; 
        } else {
            final errorData = jsonDecode(response.body);
            throw Exception(errorData['error'] ?? 'Failed to load businesses. Status: ${response.statusCode}');
        }
    } on SocketException {
        throw Exception('Network error: Could not connect to the server.');
    } catch (e) {
        throw Exception('Error fetching businesses: ${e.toString()}');
    }
  }

/// 2. Submits the new renewal application data (used by RenewalDetailScreen).
static Future<Map<String, dynamic>> submitRenewal(Map<String, dynamic> renewalData) async {
    final url = Uri.parse('$baseUrl/api/submit_renewal');
    try {
        final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(renewalData),
        );

        final responseBody = jsonDecode(response.body);

        if (response.statusCode == 200) {
            // Returns the new 'renewal_id' for use in the next step (document upload)
            return responseBody;
        } else {
            throw Exception(responseBody['message'] ?? 'Failed to submit renewal with status: ${response.statusCode}');
        }
    } on SocketException {
        throw Exception('Network error: Could not connect to the server at $baseUrl');
    } catch (e) {
        throw Exception('Error: ${e.toString()}');
    }
  }

// /// 3. Sends the document file and metadata (used by DocumentPickerScreen).
// static Future<Map<String, dynamic>> uploadDocument({
//     required String applicationId,
//     required String documentName, // The document CODE (e.g., 'CTC')
//     required File file,
//     required String documentPurpose, // 'Registration' or 'Renewal'
// }) async {
//     try {
//       var uri = Uri.parse('$baseUrl/upload_document'); 
//       var request = http.MultipartRequest('POST', uri);

//       // Keys must match request.form.get() keys in Flask
//       request.fields['application_id'] = applicationId;
//       request.fields['document_name'] = documentName; 

//       // Field name 'document' must match request.files['document'] in Flask
//       request.files.add(await http.MultipartFile.fromPath(
//           'document', 
//           file.path,
//           filename: file.path.split('/').last,
//       ));

//       var responseStreamed = await request.send();
//       final response = await http.Response.fromStream(responseStreamed);

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return {"status": "success", "message": responseData["message"]};
//       } else {
//         return {"status": "error", "message": responseData["message"] ?? "Upload failed: ${response.statusCode}"};
//       }
//     } on SocketException {
//       return {"status": "error", "message": "Network connection error. Server is unreachable."};
//     } catch (e) {
//       return {"status": "error", "message": "Exception during upload: ${e.toString()}"};
//     }
// }

  // --------------------------------------------------------
  // 3. Document & Payment Methods
  // --------------------------------------------------------

//   // ✅ Upload Document
//  /// Sends the document file and metadata to the Flask backend.
//   static Future<Map<String, dynamic>> uploadDocument({
//     required String applicationId,
//     required String documentName, // This is the document CODE (e.g., 'CTC')
//     required File file,
//   }) async {
//     try {
//       var uri = Uri.parse('$baseUrl/upload_document'); 
//       var request = http.MultipartRequest('POST', uri);

//       // 1. Add fields (application_id and document_name)
//       // These keys must match the request.form.get() keys in the Flask backend.
//       request.fields['application_id'] = applicationId;
//       request.fields['document_name'] = documentName; 

//       // 2. Add the file (as multipart/form-data)
//       // The field name 'document' must match request.files['document'] in Flask.
//       request.files.add(await http.MultipartFile.fromPath(
//           'document', 
//           file.path,
//           filename: file.path.split('/').last,
//       ));

//       // 3. Send and process response
//       var responseStreamed = await request.send();
//       final response = await http.Response.fromStream(responseStreamed);

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         // Successful upload, backend returns status: "success"
//         return {"status": "success", "message": responseData["message"]};
//       } else {
//         // Backend returns error status (e.g., 400 or 500)
//         return {"status": "error", "message": responseData["message"] ?? "Upload failed: ${response.statusCode}"};
//       }
//     } on SocketException {
//       // Network unreachable
//       return {"status": "error", "message": "Network connection error. Server is unreachable."};
//     } catch (e) {
//       // Other errors (e.g., file reading, JSON decoding)
//       return {"status": "error", "message": "Exception during upload: ${e.toString()}"};
//     }
//   }
  // // ✅ Fetch all approved businesses for renewal
  // static Future<List<dynamic>> fetchApprovedBusinesses() async {
  //   try {
  //     final response = await http.get(Uri.parse('$baseUrl/api/approved_businesses'));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return data['businesses'];
  //     } else {
  //       throw Exception('Failed to load businesses');
  //     }
  //   } catch (e) {
  //     throw Exception('Error: $e');
  //   }
  // }

  // // ✅ Submit renewal data
  // static Future<Map<String, dynamic>> submitRenewal(Map<String, dynamic> renewalData) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/api/submit_renewal'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(renewalData),
  //     );

  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     } else {
  //       throw Exception('Failed to submit renewal');
  //     }
  //   } catch (e) {
  //     throw Exception('Error: $e');
  //   }
  // }

  

  
    // Download Certificate
  static Future<String> downloadPermitToLocalPath(int applicationId) async {
    try {
      // 1. Construct URL and Fetch PDF bytes
      final url = Uri.parse('$baseUrl/user/download_permit/$applicationId');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        // This catches Flask errors (e.g., 403 Forbidden if not Approved)
        throw Exception('Failed to fetch permit. Status: ${response.statusCode}');
      }

      // 2. Get a temporary directory to save the file
      final dir = await getTemporaryDirectory();
      final fileName = 'mayor_permit_$applicationId.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // 3. Write the fetched bytes to the temporary file
      await file.writeAsBytes(response.bodyBytes);
      
      return filePath;

    } catch (e) {
      // Return a structured error message
      throw Exception('Error preparing PDF for view: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/create_payment");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("❌ Server Error [${response.statusCode}]: ${response.body}");
        return {
          "success": false,
          "message": "Failed to create payment. Please try again."
        };
      }
    } catch (e) {
      print("⚠️ Error in createPayment(): $e");
      return {"success": false, "message": "Network or server error: $e"};
    }
  }

  // --------------------------
  // 📊 GET PAYMENT STATUS
  // --------------------------
  static Future<Map<String, dynamic>> getPaymentStatus(String applicationId) async {
    final url = Uri.parse("$baseUrl/get_payment_status?application_id=$applicationId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Error [${response.statusCode}]: ${response.body}");
        return {"success": false, "message": "Failed to get payment status"};
      }
    } catch (e) {
      print("⚠️ Error in getPaymentStatus(): $e");
      return {"success": false, "message": "Network or server error: $e"};
    }
  }


//   //Payment
// static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
//     final url = Uri.parse('$baseUrl/create_payment');

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(data), // Encodes the Dart map into a JSON string
//       );

//       // Handles 200, 400, or 500 status codes. Flask typically returns JSON for errors.
//       if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 500) {
//         return jsonDecode(response.body);
//       } else {
//         // Handle unexpected server status codes (e.g., 502)
//         print("Error: ${response.statusCode} - ${response.body}");
//         return {"success": false, "message": "Server error (${response.statusCode})"};
//       }
//     } catch (e) {
//       // Handle network errors (server is down or connection refused)
//       print("Network Error in createPayment: $e");
//       return {"success": false, "message": "Network connection error. Check if server is running at $baseUrl"};
//     }
//   }

  // --------------------------------------------------------
  // 2. GET Request: Fetch Pending Application ID from DB
  // --------------------------------------------------------
  // static Future<Map<String, dynamic>> getPendingApplication(String userId) async {
  //   // Formats the URL with the user_id as a query parameter
  //   final url = Uri.parse('$baseUrl/get_pending_application?user_id=$userId');

  //   try {
  //     final response = await http.get(url);

  //     // Handles 200 (Found) or 404 (Not Found) responses from the server
  //     if (response.statusCode == 200 || response.statusCode == 404) {
  //       return jsonDecode(response.body);
  //     } else {
  //       // Handle unexpected server status codes
  //       print("Error: ${response.statusCode} - ${response.body}");
  //       return {"success": false, "message": "Failed to fetch application data. Server returned ${response.statusCode}"};
  //     }
  //   } catch (e) {
  //     // Handle network errors
  //     print("Network Error in getPendingApplication: $e");
  //     return {"success": false, "message": "Network connection error. Check if server is running at $baseUrl"};
  //   }
  // }
  
}

