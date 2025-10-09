import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.43.98:5000"; // Replace with your IP

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
      );

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
  // ---------- Submit Application ----------
  static Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/submit_application');
    print("📤 Sending data to backend: ${jsonEncode(data)}"); // debug log

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("📥 Response: ${response.body}"); // debug log
    return jsonDecode(response.body);
  }

  // ✅ Upload Document
  static Future<Map<String, dynamic>> uploadDocument({
    required String applicationId,
    required String documentName,
    required File file,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/upload_document');
      var request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['application_id'] = applicationId;
      request.fields['document_name'] = documentName;

      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Send request
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData);
      } else {
        final errorData = await response.stream.bytesToString();
        return {"status": "error", "message": "Upload failed: $errorData"};
      }
    } catch (e) {
      return {"status": "error", "message": "Exception: $e"};
    }
  }
}

//     required String lastName,
//     String? middleName,
//     required String email,
//     required String password,
//     required String mobileNumber,
//   }) async {
//     final url = Uri.parse("$baseUrl/signup");

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({
//           "first_name": firstName,
//           "last_name": lastName,
//           "middle_name": middleName ?? "",
//           "email": email,
//           "password": password, // Sedning plain text password; ensure HTTPS in production
//           "mobile_number": mobileNumber,
//         }),
//       );

//       final data = json.decode(response.body);

//       if (response.statusCode == 201) {
//         return data; // {"message": "User registered successfully!"}
//       } else {
//         return {"error": data["error"] ?? "Unknown error"};
//       }
//     } catch (e) {
//       return {"error": "Failed to connect to server: $e"};
//     }
//   }
//   /// Signin API
//   static Future<Map<String, dynamic>> signin({
//     required String email,
//     required String password,
//   }) async {
//     final url = Uri.parse("$baseUrl/signin");

//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "email": email,
//         "password": password,
//       }),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body); // {status: success, user: {...}}
//     } else {
//       return {
//         "status": "error",
//         "message": jsonDecode(response.body)["message"] ??
//             "Something went wrong"
//       };
//     }
//   }

  
//   // ---------------- SUBMIT APPLICATION ----------------
//   static Future<Map<String, dynamic>> submitApplication(
//       Map<String, dynamic> formData) async {
//     try {
//     // Map frontend keys to backend keys with defaults
//       Map<String, dynamic> payload = {
//         "first_name": formData["firstName"] ?? "",
//         "last_name": formData["lastName"] ?? "",
//         "middle_name": formData["middleName"] ?? "",
//         "business_name": formData["businessName"] ?? "",
//         "account_number": formData["accountNumber"] ?? "",
//         "application_type": formData["applicationType"] ?? "",
//         "application_date": formData["applicationDate"] ?? "",
//         "tin_no": formData["tinNo"] ?? "",
//         "mode_of_payment": formData["modeOfPayment"] ?? "",
//         "business_type": formData["businessType"] ?? "",
//         "amendment_from": formData["amendmentFrom"] ?? "",
//         "amendment_to": formData["amendmentTo"] ?? "",
//         "details": {
//           "business_address": formData["details"]?["businessAddress"] ?? "",
//           "postal_code": formData["details"]?["postalCode"] ?? "",
//           "owner_address": formData["details"]?["ownerAddress"] ?? "",
//           "owner_email": formData["details"]?["ownerEmail"] ?? "",
//           "owner_mobile": formData["details"]?["ownerMobile"] ?? "",
//           "emergency_contact": formData["details"]?["emergencyContact"] ?? "",
//           "emergency_email": formData["details"]?["emergencyEmail"] ?? "",
//           "emergency_mobile": formData["details"]?["emergencyMobile"] ?? "",
//           "business_area": formData["details"]?["businessArea"] ?? 0,
//           "employees_total": formData["details"]?["employeesTotal"] ?? 0,
//           "employees_with_lgu": formData["details"]?["employeesWithLgu"] ?? 0,
//           "is_rented": formData["details"]?["isRented"] ?? false,
//           "lessor": {
//             "lessor_name": formData["details"]?["lessor"]?["lessorName"] ?? "",
//             "lessor_address": formData["details"]?["lessor"]?["lessorAddress"] ?? "",
//             "lessor_email": formData["details"]?["lessor"]?["lessorEmail"] ?? "",
//             "lessor_mobile": formData["details"]?["lessor"]?["lessorMobile"] ?? "",
//             "monthly_rent": formData["details"]?["lessor"]?["monthlyRent"] ?? 0,
//           },
//         },
//         "business_activity": {
//           "line_of_business": formData["businessActivity"]?["lineOfBusiness"] ?? "",
//           "num_of_units": formData["businessActivity"]?["numOfUnits"] ?? 0,
//           "capitalization": formData["businessActivity"]?["capitalization"] ?? 0,
//           "gross_sales_essential": formData["businessActivity"]?["grossSalesEssential"] ?? 0,
//           "gross_sales_nonessential": formData["businessActivity"]?["grossSalesNonessential"] ?? 0,
//        },
//       };

//       final response = await http.post(
//         Uri.parse("$baseUrl/submit_application"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(payload),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return data;
//       } else {
//         return {
//           "status": "error",
//           "message":
//               "Server Error: ${response.statusCode} - ${data['message'] ?? response.body}"
//         };
//       }
//     } catch (e) {
//       return {"status": "error", "message": "Failed to connect: $e"};
//     }
//   }

//   /// ---------------- UPLOAD DOCUMENT ----------------
//   static Future<Map<String, dynamic>> uploadDocument({
//     required int applicationId,
//     required String documentName,
//     required String filePath,
//   }) async {
//     var uri = Uri.parse("$baseUrl/upload_document");

//     var request = http.MultipartRequest('POST', uri)
//       ..fields['application_id'] = applicationId.toString()
//       ..fields['document_name'] = documentName
//       ..files.add(await http.MultipartFile.fromPath('file', filePath));

//     var streamedResponse = await request.send();
//     var response = await http.Response.fromStream(streamedResponse);

//     return json.decode(response.body);
//   }

// }


