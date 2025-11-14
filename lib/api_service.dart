import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // BASE URL REMAINS THE SAME
  static const String baseUrl = "http://192.168.100.203:5000"; 

  // --------------------------------------------------------
  // 1. AUTH ROUTES (/api/auth)
  // --------------------------------------------------------

  // ---------- Signup ----------
  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    // MODIFIED: From /signup to /api/auth/signup
    final url = Uri.parse('$baseUrl/api/auth/signup'); 
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

    // ... (rest of the error handling remains the same) ...
    if (response.statusCode == 201) { // Changed to 201 as per standard
      return jsonDecode(response.body);
    } else {
      // Decode error message from backend for better feedback
      final errorData = jsonDecode(response.body);
      return {"status": "error", "message": errorData["error"] ?? "Sign Up failed"};
    }
  }

  // ---------- Signin ----------
  static Future<Map<String, dynamic>> signin({
    required String email,
    required String password,
  }) async {
    try {
      // MODIFIED: From /signin to /api/auth/signin
      final url = Uri.parse('$baseUrl/api/auth/signin'); 
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      
      // ... (rest of the logic remains the same) ...
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data["status"] == "success" && data["user"] != null) {
            return {
              "status": "success",
              "message": data["message"] ?? "Login successful",
              "user": data["user"], 
            };
          } else {
            return {
              "status": "error",
              "message": data["message"] ?? "Invalid credentials"
            };
          }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "status": "error",
          "message": errorData["message"] ?? "Invalid credentials or server issue"
        };
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // ---------- Forgot Password ----------
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      // MODIFIED: From /forgot_password to /api/auth/forgot_password
      final url = Uri.parse('$baseUrl/api/auth/forgot_password'); 
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      // ... (rest of the logic remains the same) ...
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
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

  // --------------------------------------------------------
  // 2. APPLICATION ROUTES (/api/applications)
  // --------------------------------------------------------

  // ---------- Submit Application ----------
  static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    // MODIFIED: From /submit_application to /api/applications/submit
    final url = Uri.parse('$baseUrl/api/applications/submit');
    print("📤 Sending data to backend: ${jsonEncode(data)}"); // debug log

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("📥 Response: ${response.body}"); // debug log
    return jsonDecode(response.body);
  }
  // --- APPLICATION & RENEWAL ROUTES ---
  
  // MODIFIED: Accepts userId to filter results
  static Future<List<dynamic>> fetchApprovedBusinesses(String userId) async {
    // Note: The backend endpoint is defined as /api/applications/approved_businesses
    // and should be updated on the backend to filter by user_id
    final url = Uri.parse('$baseUrl/api/applications/approved_businesses?user_id=$userId'); 
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('businesses')) {
          // Returns the list of approved businesses for the user
          return data['businesses']; 
        } else {
          throw Exception('Server returned success but missing "businesses" key.');
        }
      } else {
        // Try to decode error message from the backend
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Server error: Status ${response.statusCode}');
        } catch (_) {
          throw Exception('Failed to load businesses. Status: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw Exception('Network error: Could not connect to the server at $baseUrl');
    } catch (e) {
      throw Exception('Error: Failed to load businesses. Details: ${e.toString()}');
    }
  }

  // ✅ Upload Document (Used by UploadDocumentPage)
  static Future<Map<String, dynamic>> uploadDocument({
    required String applicationId,
    required String documentName, // The document CODE (e.g., 'CTC')
    required File file,
    required String documentPurpose, // 🛑 CRITICAL: This holds the dynamic application type
}) async {
    final url = Uri.parse('$baseUrl/upload_document'); 
    try {
      var request = http.MultipartRequest('POST', url);

      // 1. Add fields (must match request.form.get() keys in Flask)
      request.fields['application_id'] = applicationId;
      request.fields['document_name'] = documentName; 
      request.fields['document_purpose'] = documentPurpose; // ⬅️ SENDS DYNAMIC PURPOSE

      // 2. Add the file (field name 'document' must match request.files['document'] in Flask)
      request.files.add(await http.MultipartFile.fromPath(
          'document', 
          file.path,
          filename: file.path.split('/').last,
      ));

      // 3. Send and process response
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
  // ---------- Get Previous Applications (Dashboard View) ----------
  static Future<Map<String, dynamic>> getPreviousApplications(String userId) async {
    // MODIFIED: From /user/applications/$userId to /api/applications/user_applications/$userId
    final url = Uri.parse('$baseUrl/api/applications/user_applications/$userId');
    
    try {
      final response = await http.get(url);

      // ... (rest of the logic remains the same) ...
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "data": data,
          "message": "Previous applications fetched successfully"
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "Failed to fetch previous applications"
        };
      }
    } on SocketException {
      return {"success": false, "message": "No internet connection"};
    } catch (e) {
      return {"success": false, "message": "An unexpected error occurred: ${e.toString()}"};
    }
  }

  // --------------------------------------------------------
  // 3. PAYMENT ROUTES (/api/payments)
  // --------------------------------------------------------

  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    // MODIFIED: From /create_payment to /api/payments/create
    final url = Uri.parse("$baseUrl/api/payments/create");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      // ... (rest of the logic remains the same) ...
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
    // MODIFIED: From /get_payment_status to /api/payments/status
    final url = Uri.parse("$baseUrl/api/payments/status?application_id=$applicationId");
    try {
      final response = await http.get(url);
      
      // ... (rest of the logic remains the same) ...
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

  // --------------------------------------------------------
  // 4. DOCUMENTS ROUTES (/api/documents)
  // --------------------------------------------------------

  // // ✅ Upload Document
  // /// Sends the document file and metadata to the Flask backend.
  // static Future<Map<String, dynamic>> uploadDocument({
  //   required String applicationId,
  //   required String documentName, // This is the document CODE (e.g., 'CTC')
  //   required File file,
  // }) async {
  //   try {
  //     // MODIFIED: From /upload_document to /api/documents/upload
  //     var uri = Uri.parse('$baseUrl/api/documents/upload'); 
  //     var request = http.MultipartRequest('POST', uri);

  //     // ... (rest of the logic remains the same) ...
  //     request.fields['application_id'] = applicationId;
  //     request.fields['document_name'] = documentName; 

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

  // Download Certificate
  static Future<String> downloadPermitToLocalPath(int applicationId) async {
    try {
      // MODIFIED: From /user/download_permit/$applicationId to /api/documents/download/$applicationId
      final url = Uri.parse('$baseUrl/api/documents/download/$applicationId');
      final response = await http.get(url);

      // ... (rest of the logic remains the same) ...
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch permit. Status: ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final fileName = 'mayor_permit_$applicationId.pdf';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);
      return filePath;

    } catch (e) {
      throw Exception('Error preparing PDF for view: ${e.toString()}');
    }
  }

  // --------------------------------------------------------
  // 5. OTHER UTILITY ROUTES
  // --------------------------------------------------------

  // 2. GET Request: Fetch Pending Application ID from DB
  static Future<Map<String, dynamic>> getPendingApplication(String userId) async {
    // MODIFIED: From /get_pending_application to /api/applications/pending_id
    final url = Uri.parse('$baseUrl/api/applications/pending_id?user_id=$userId');

    try {
      final response = await http.get(url);

      // ... (rest of the logic remains the same) ...
      if (response.statusCode == 200 || response.statusCode == 404) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return {"success": false, "message": "Failed to fetch application data. Server returned ${response.statusCode}"};
      }
    } catch (e) {
      print("Network Error in getPendingApplication: $e");
      return {"success": false, "message": "Network connection error. Check if server is running at $baseUrl"};
    }
  }
}