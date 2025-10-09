import json
import uuid
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql
from datetime import date

app = Flask(__name__)
CORS(app)

# ---------------- DATABASE CONFIGURATION ----------------
db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "capstone_db"
}

def get_db_connection():
    return pymysql.connect(**db_config)

# # ---------------- UPLOAD CONFIG ----------------
# UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'}

# def allowed_file(filename):
#     return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route("/")
def home():
    return {"message": "Flask backend is running!"}

# ✅ SIGN UP
@app.route("/signup", methods=["POST"])
def signup():
    data = request.json
    required = ["first_name", "last_name", "email", "password", "mobile_number"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    password_hash = generate_password_hash(data["password"])

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO users (first_name, last_name, middle_name, email, password_hash, mobile_number)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data["first_name"], data["last_name"], data.get("middle_name", ""),
              data["email"], password_hash, data["mobile_number"]))
        conn.commit()
        return jsonify({"message": "User registered successfully!"}), 201
    except pymysql.err.IntegrityError:
        return jsonify({"error": "Email already exists"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ✅ SIGN IN
@app.route("/signin", methods=["POST"])
def signin():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"status": "error", "message": "Email and password are required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT user_id, email, first_name, last_name, password_hash FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"status": "error", "message": "Invalid credentials"}), 401

        user_id, email, first_name, last_name, password_hash = user
        if check_password_hash(password_hash, password):
            return jsonify({
                "status": "success",
                "message": "Login successful",
                "user": {"user_id": user_id, "email": email, "first_name": first_name, "last_name": last_name}
            }), 200
        else:
            return jsonify({"status": "error", "message": "Invalid credentials"}), 401
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ✅ SUBMIT APPLICATIONp
@app.route("/submit_application", methods=["POST"])
def submit_application():
    data = request.get_json()

    print(f"📥 Received data from Flutter: {json.dumps(data, indent=2)}")

    user_id = data.get("user_id")

    # 1. Basic validation
    if not user_id:
        return jsonify({"status": "error", "message": "Missing user_id. Please log in again."}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
    except Exception as e:
        print(f"Database Connection Error: {e}")
        return jsonify({"status": "error", "message": "Failed to connect to the database."}), 500


    try:
        # --- 1. Insert taxpayer (Taxpayer information from Screen 1) ---
        # 8 columns being inserted
        cursor.execute("""
            INSERT INTO taxpayers (first_name, last_name, middle_name, trade_name, businessName, account_number, has_tax_incentive, tax_incentive_entity)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data.get("first_name", ""),
            data.get("last_name", ""),
            data.get("middle_name", ""),
            data.get("trade_name", ""),
            data.get("businessName", ""),
            data.get("account_number", ""),
            data.get("has_tax_incentive", 0), # Assumed 0/1 integer
            data.get("tax_incentive_entity", "")
        ))
        taxpayer_id = cursor.lastrowid
        
        if not taxpayer_id:
             raise Exception("Failed to get last inserted Taxpayer ID. Check DB setup.")

        # --- 2. Insert business application (Core Application details from Screen 1) ---
        # 9 columns being inserted - THE FIX IS HERE (removed the trailing comma in the tuple)
        cursor.execute("""
            INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date,
                                             tin_no, mode_of_payment, business_type, amendment_from, amendment_to)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            user_id,
            taxpayer_id,
            data.get("application_type", ""),
            data.get("application_date", str(date.today())), # Uses the date string from Flutter
            data.get("tin_no", ""),
            data.get("mode_of_payment", ""),
            data.get("business_type", ""),
            data.get("amendment_from", ""),
            data.get("amendment_to", "") # <--- NO COMMA HERE! (Fixes the Python tuple error)
        ))
        application_id = cursor.lastrowid
        
        if not application_id:
            raise Exception("Failed to get last inserted Application ID. Check DB setup.")
        
        # --- 3. Insert application details (Address, Contact, Employees from Screen 2) ---
        # NOTE: Your database uses is_rented ENUM('Owned','Rented'). Flutter sends 0/1. 
        # We must convert 0/1 to 'Owned'/'Rented' for insertion.
        is_rented_val = data.get("is_rented", 0) # Assumed 0/1 integer
        is_rented_db_value = 'Rented' if is_rented_val == 1 else 'Owned'
        
        # NOTE: business_area is decimal(10,2) in DB, needs float conversion
        business_area_val = float(data.get("business_area", 0.0) or 0.0)

        cursor.execute("""
            INSERT INTO application_details (application_id, business_address, postal_code, owner_address,
                                             owner_email, owner_mobile, emergency_contact, emergency_email,
                                             emergency_mobile, business_area, employees_total, employees_with_lgu,
                                             is_rented)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            application_id,
            data.get("business_address", ""),
            data.get("postal_code", ""),
            data.get("owner_address", ""),
            data.get("owner_email", ""),
            data.get("owner_mobile", ""),
            data.get("emergency_contact", ""),
            data.get("emergency_email", ""),
            data.get("emergency_mobile", ""),
            business_area_val,
            data.get("employees_total", 0),
            data.get("employees_with_lgu", 0),
            is_rented_db_value # <--- Using the converted ENUM value
        ))

        # --- 4. Insert lessor info (if rented) ---
        if is_rented_val == 1:
            # monthly_rent is decimal(10,2)
            monthly_rent_val = float(data.get("monthly_rent", 0.0) or 0.0) 
            
            cursor.execute("""
                INSERT INTO lessors (application_id, lessor_name, lessor_address, lessor_email,
                                     lessor_mobile, monthly_rent)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                application_id,
                data.get("lessor_name", ""),
                data.get("lessor_address", ""),
                data.get("lessor_email", ""),
                data.get("lessor_mobile", ""),
                monthly_rent_val 
            ))

        # --- 5. Insert business activities (Line of Business/Sales from Screen 3) ---
        # NOTE: Your DB uses gross_sales_nonessential (one 's'), Flutter sends gross_sales_non_essential (two 's')
        cursor.execute("""
            INSERT INTO business_activities (application_id, line_of_business, num_of_units,
                                             capitalization, gross_sales_essential, gross_sales_nonessential)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            application_id,
            data.get("line_of_business", ""),
            int(data.get("num_of_units", 0) or 0), # capitalization and sales are decimal(15,2)
            float(data.get("capitalization", 0.0) or 0.0), 
            float(data.get("gross_sales_essential", 0.0) or 0.0),
            float(data.get("gross_sales_non_essential", 0.0) or 0.0) # <--- Flutter key
        ))

        # Commit all successful insertions
        conn.commit()
        
        print(f"✅ Application successfully submitted and committed. ID: {application_id}")

        return jsonify({
            "status": "success",
            "message": "Application submitted successfully!",
            "application_id": application_id
        }), 201

    except Exception as e:
        if 'conn' in locals() and conn:
            conn.rollback()
        
        import traceback
        print(f"❌ Database error during submission. Rolling back transaction.")
        traceback.print_exc()

        return jsonify({"status": "error", "message": f"Submission failed due to server error. Details: {str(e)}"}), 500

    finally:
        if 'conn' in locals() and conn:
            conn.close()
# @app.route("/submit_application", methods=["POST"])
# def submit_application():
#     data = request.get_json()

#     user_id = data.get("user_id")
#     taxpayer = data.get("taxpayer", {})
#     application = data.get("application", {})
#     business_activities = data.get("business_activity", [])
#     application_detail = data.get("application_detail", {})
#     lessor = data.get("lessor", {})

#     if not user_id:
#         return jsonify({"status": "error", "message": "Missing user_id"}), 400

#     conn = get_db_connection()
#     cursor = conn.cursor()

#     try:
#         # Insert taxpayer
#         cursor.execute("""
#             INSERT INTO taxpayers (first_name, last_name, middle_name, businessName, account_number)
#             VALUES (%s, %s, %s, %s, %s)
#         """, (
#             taxpayer.get("first_name", ""), 
#             taxpayer.get("last_name", ""), 
#             taxpayer.get("middle_name", ""), 
#             taxpayer.get("trade_name", ""), 
#             taxpayer.get("tax_incentive_entity", "")
#         ))
#         taxpayer_id = cursor.lastrowid

#         # Insert business application
#         cursor.execute("""
#             INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date,
#                                                tin_no, mode_of_payment, business_type)
#             VALUES (%s, %s, %s, %s, %s, %s, %s)
#         """, (
#             user_id,
#             taxpayer_id,
#             application.get("application_type", ""),
#             str(date.today()),
#             application.get("tin_no", ""),
#             application.get("mode_of_payment", ""),
#             application.get("business_type", "")
#         ))
#         application_id = cursor.lastrowid

#         # Insert business activities (loop)
#         for activity in business_activities:
#             cursor.execute("""
#                 INSERT INTO business_activities (application_id, line_of_business, num_of_units,
#                                                  capitalization, gross_sales_essential, gross_sales_non_essential)
#                 VALUES (%s, %s, %s, %s, %s, %s)
#             """, (
#                 application_id,
#                 activity.get("line_of_business", ""),
#                 activity.get("num_of_units", 0),
#                 activity.get("capitalization", 0),
#                 activity.get("gross_sales_essential", 0),
#                 activity.get("gross_sales_non_essential", 0)
#             ))

#         # Insert application details
#         cursor.execute("""
#             INSERT INTO application_details (application_id, business_address, postal_code, owner_address,
#                                              owner_email, owner_mobile, emergency_contact, emergency_email,
#                                              emergency_mobile, business_area, employees_total, employees_with_lgu,
#                                              is_rented)
#             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
#         """, (
#             application_id,
#             application_detail.get("business_address", ""),
#             application_detail.get("postal_code", ""),
#             application_detail.get("owner_address", ""),
#             application_detail.get("owner_email", ""),
#             application_detail.get("owner_mobile", ""),
#             application_detail.get("emergency_contact", ""),
#             application_detail.get("emergency_email", ""),
#             application_detail.get("emergency_mobile", ""),
#             application_detail.get("business_area", 0),
#             application_detail.get("employees_total", 0),
#             application_detail.get("employees_with_lgu", 0),
#             application_detail.get("is_rented", False)
#         ))

#         # Insert lessor info (if rented)
#         if application_detail.get("is_rented", False):
#             cursor.execute("""
#                 INSERT INTO lessors (application_id, lessor_name, lessor_address, lessor_email,
#                                      lessor_mobile, monthly_rent)
#                 VALUES (%s, %s, %s, %s, %s, %s)
#             """, (
#                 application_id,
#                 lessor.get("lessor_name", ""),
#                 lessor.get("lessor_address", ""),
#                 lessor.get("lessor_email", ""),
#                 lessor.get("lessor_mobile", ""),
#                 lessor.get("monthly_rent", 0)
#             ))

#         conn.commit()
#         return jsonify({
#             "status": "success",
#             "message": "Application submitted successfully!",
#             "application_id": application_id
#         }), 200

#     except Exception as e:
#         conn.rollback()
#         return jsonify({"status": "error", "message": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


###########################################################################
# The code below is the refactored version of the previous code.
# import uuid
# import os
# from flask import Flask, request, jsonify
# from flask_cors import CORS
# from werkzeug.utils import secure_filename
# from werkzeug.security import generate_password_hash, check_password_hash
# import pymysql
# from datetime import date

# app = Flask(__name__)
# CORS(app)

# # ---------------- DATABASE CONFIG ----------------
# db_config = {
#     "host": "localhost",
#     "user": "root",
#     "password": "",
#     "database": "capstone_db"
# }

# def get_db_connection():
#     return pymysql.connect(**db_config)

# # ---------------- UPLOAD CONFIG ----------------
# UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'}

# def allowed_file(filename):
#     return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# # ---------------- ROUTES ----------------

# @app.route("/")
# def home():
#     return {"message": "Flask backend is running!"}

# # ✅ SIGN UP
# @app.route("/signup", methods=["POST"])
# def signup():
#     data = request.json
#     required = ["first_name", "last_name", "email", "password", "mobile_number"]
#     missing = [f for f in required if not data.get(f)]
#     if missing:
#         return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

#     password_hash = generate_password_hash(data["password"])

#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor()
#         cursor.execute("""
#             INSERT INTO users (first_name, last_name, middle_name, email, password_hash, mobile_number)
#             VALUES (%s, %s, %s, %s, %s, %s)
#         """, (data["first_name"], data["last_name"], data.get("middle_name", ""),
#               data["email"], password_hash, data["mobile_number"]))
#         conn.commit()
#         return jsonify({"message": "User registered successfully!"}), 201
#     except pymysql.err.IntegrityError:
#         return jsonify({"error": "Email already exists"}), 400
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

# # ✅ SIGN IN
# @app.route("/signin", methods=["POST"])
# def signin():
#     data = request.json
#     email = data.get("email")
#     password = data.get("password")
#     if not email or not password:
#         return jsonify({"status": "error", "message": "Email and password are required"}), 400

#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor()
#         cursor.execute("SELECT user_id, email, first_name, last_name, password_hash FROM users WHERE email=%s", (email,))
#         user = cursor.fetchone()

#         if not user:
#             return jsonify({"status": "error", "message": "Invalid credentials"}), 401

#         user_id, email, first_name, last_name, password_hash = user
#         if check_password_hash(password_hash, password):
#             return jsonify({
#                 "status": "success",
#                 "message": "Login successful",
#                 "user": {"user_id": user_id, "email": email, "first_name": first_name, "last_name": last_name}
#             }), 200
#         else:
#             return jsonify({"status": "error", "message": "Invalid credentials"}), 401
#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

# # ✅ SUBMIT APPLICATION
# @app.route("/submit_application", methods=["POST"])
# def submit_application():
#     data = request.get_json()
#     conn = get_db_connection()
#     cursor = conn.cursor()

#     try:
#         user_id = data.get("user_id")
#         cursor.execute("SELECT email FROM users WHERE user_id=%s", (user_id,))
#         user = cursor.fetchone()
#         if not user:
#             return jsonify({"status": "error", "message": "User not found"}), 404
#         user_email = user[0]

#         # Insert taxpayer
#         cursor.execute("""
#             INSERT INTO taxpayers (first_name, last_name, middle_name, businessName, account_number)
#             VALUES (%s, %s, %s, %s, %s)
#         """, (data.get("first_name", ""), data.get("last_name", ""), data.get("middle_name", ""),
#               data.get("businessName", ""), data.get("account_number", "")))
#         taxpayer_id = cursor.lastrowid

#         # Insert business application
#         cursor.execute("""
#             INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date,
#                                                tin_no, mode_of_payment, business_type, amendment_from, amendment_to)
#             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
#         """, (user_id, taxpayer_id, data.get("application_type", ""), str(date.today()),
#               data.get("tin_no", ""), data.get("mode_of_payment", ""), data.get("business_type", ""),
#               data.get("amendment_from", ""), data.get("amendment_to", "")))
#         application_id = cursor.lastrowid

#         conn.commit()
#         return jsonify({
#             "status": "success",
#             "message": "Application submitted successfully!",
#             "application_id": application_id,
#             "user_email": user_email
#         }), 200
#     except Exception as e:
#         conn.rollback()
#         return jsonify({"status": "error", "message": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

# # ✅ UPLOAD DOCUMENT
# @app.route("/upload_document", methods=["POST"])
# def upload_document():
#     try:
#         application_id = request.form.get("application_id")
#         document_name = request.form.get("document_name")
#         file = request.files.get("file")

#         if not file or not allowed_file(file.filename):
#             return jsonify({"status": "error", "message": "Invalid or missing file"}), 400

#         filename = f"{uuid.uuid4().hex}_{secure_filename(file.filename)}"
#         file_path = os.path.join(UPLOAD_FOLDER, filename)
#         file.save(file_path)

#         conn = get_db_connection()
#         cursor = conn.cursor()
#         cursor.execute("""
#             INSERT INTO uploaded_documents (application_id, document_name, file_path)
#             VALUES (%s, %s, %s)
#         """, (application_id, document_name, filename))
#         conn.commit()
#         return jsonify({"status": "success", "message": "File uploaded successfully!"}), 200
#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)

############################################################################
# The code below is the previous version before refactoring.

# import uuid
# from flask import Flask, request, jsonify
# from flask_cors import CORS
# import pymysql
# from datetime import date
# from werkzeug.security import generate_password_hash, check_password_hash 
# import os
# from werkzeug.utils import secure_filename


# #from db import get_db

# app = Flask(__name__)
# CORS(app)

# # Database config 
# db_config = {
#     "host": "localhost",
#     "user": "root",
#     "password": "",
#     "database": "capstone_db"
# }

# def get_db_connection():
#     return pymysql.connect(**db_config)

# # ----------------Upload folder config----------------
# UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
# if not os.path.exists(UPLOAD_FOLDER):
#     os.makedirs(UPLOAD_FOLDER)

# def allowed_file(filename):
#     ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf', 'doc', 'docx'}
#     return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# # -----------------------------------------------------------

# @app.route("/")
# def home():
#     return {"message": "Flask backend is running!"}

# @app.route("/signup", methods=["POST"])
# def signup():
#     data = request.json
#     print("Received data:", data)  # Debugging line
    
#     first_name = data.get("first_name")
#     last_name = data.get("last_name")
#     middle_name = data.get("middle_name")
#     email = data.get("email")
#     password = data.get("password")
#     mobile_number = data.get("mobile_number")

#     required_fields = {"first_name": first_name, "last_name": last_name, "email": email, "password": password, "mobile_number": mobile_number}

#     missing = [field for field, value in required_fields.items() if not value]
#     if missing:
#         return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

#     password_hash = generate_password_hash(password)

#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor()
#         cursor.execute(
#             "INSERT INTO users (first_name, last_name, middle_name, email, password_hash, mobile_number) VALUES (%s, %s, %s, %s, %s, %s)",
#             (first_name, last_name, middle_name, email, password_hash, mobile_number)
#         )
#         conn.commit()
#         return jsonify({"message": "User registered successfully!"}), 201
    
#     except pymysql.err.IntegrityError as e:
#         #Duplicate email error

#         if "Duplicate entry" in str(e):
#             return jsonify({"error": "Email already exists"}), 400
#         return jsonify({"error":"Database integrity error"}), 400
   
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()

# #----------------Signin route----------------
# @app.route('/signin', methods=['POST'])
# def signin():
#     data = request.json
#     email = data.get('email')
#     password = data.get('password')

#     if not email or not password:
#         return jsonify({"status": "error", "message": "Email and password are required"}), 400

#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor()

#         # Fetch user by email
#         query = "SELECT user_id, email, first_name, last_name, password_hash FROM users WHERE email=%s"
#         cursor.execute(query, (email,))
#         result = cursor.fetchone()

#         if not result:
#             return jsonify({"status": "error", "message": "Invalid credentials"}), 401

#         # Unpack results
#         user_id, email, first_name, last_name, password_hash = result

#         # Check hashed password
#         if check_password_hash(password_hash, password):
#             return jsonify({
#                 "status": "success",
#                 "message": "Login successful",
#                 "user": {
#                     "user_id": user_id,
#                     "email": email,
#                     "first_name": first_name,
#                     "last_name": last_name,
                    
#                 }
#             }), 200
#         else:
#             return jsonify({"status": "error", "message": "Invalid credentials"}), 401

#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 500

#     finally:
#         cursor.close()
#         conn.close()
        
# # ---------------- SUBMIT APPLICATION ROUTE ----------------
# @app.route("/submit_application", methods=["POST"])
# def submit_application():
#     data = request.get_json()
#     conn = get_db_connection()
#     cursor = conn.cursor()

#     try:
#         user_id = data.get("user_id")
#         if not user_id:
#             return jsonify({"status": "error", "message": "Missing user_id"}), 400

#         # ✅ Automatically get user email from database
#         cursor.execute("SELECT email FROM users WHERE user_id = %s", (user_id,))
#         user_result = cursor.fetchone()
#         if not user_result:
#             return jsonify({"status": "error", "message": "User not found"}), 404

#         user_email = user_result[0]  # retrieved email

#         # ✅ Insert taxpayer
#         cursor.execute("""
#             INSERT INTO taxpayers (first_name, last_name, middle_name, businessName, account_number)
#             VALUES (%s, %s, %s, %s, %s)
#         """, (
#             data.get("first_name", ""),
#             data.get("last_name", ""),
#             data.get("middle_name", ""),
#             data.get("businessName", ""),
#             data.get("account_number", "")
#         ))
#         taxpayer_id = cursor.lastrowid

#         # ✅ Insert business application
#         cursor.execute("""
#             INSERT INTO business_applications
#             (user_id, taxpayer_id, application_type, application_date, tin_no, mode_of_payment,
#              business_type, amendment_from, amendment_to)
#             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
#         """, (
#             user_id,
#             taxpayer_id,
#             data.get("application_type", ""),
#             data.get("application_date", str(date.today())),
#             data.get("tin_no", ""),
#             data.get("mode_of_payment", ""),
#             data.get("business_type", ""),
#             data.get("amendment_from", ""),
#             data.get("amendment_to", "")
#         ))
#         application_id = cursor.lastrowid

#         # ✅ Insert details
#         details = data.get("details", {})
#         if details:
#             cursor.execute("""
#                 INSERT INTO application_details
#                 (application_id, business_address, postal_code, owner_address, owner_email, owner_mobile,
#                  emergency_contact, emergency_email, emergency_mobile, business_area, employees_total,
#                  employees_with_lgu, is_rented)
#                 VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
#             """, (
#                 application_id,
#                 details.get("business_address", ""),
#                 details.get("postal_code", ""),
#                 details.get("owner_address", ""),
#                 user_email,  # ✅ use user's email automatically
#                 details.get("owner_mobile", ""),
#                 details.get("emergency_contact", ""),
#                 details.get("emergency_email", ""),
#                 details.get("emergency_mobile", ""),
#                 details.get("business_area", 0),
#                 details.get("employees_total", 0),
#                 details.get("employees_with_lgu", 0),
#                 details.get("is_rented", "Owned")
#             ))

#         # ✅ Insert lessor info if rented
#         if details.get("is_rented") == "Rented":
#             lessor = details.get("lessor", {})
#             cursor.execute("""
#                 INSERT INTO lessors
#                 (application_id, lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent)
#                 VALUES (%s, %s, %s, %s, %s, %s)
#             """, (
#                 application_id,
#                 lessor.get("lessor_name", ""),
#                 lessor.get("lessor_address", ""),
#                 lessor.get("lessor_email", ""),
#                 lessor.get("lessor_mobile", ""),
#                 lessor.get("monthly_rent", 0)
#             ))

#         # ✅ Insert business activity
#         business_activity = data.get("business_activity", {})
#         if business_activity:
#             def clean_number(value):
#                 if value is None or value == "":
#                     return 0
#                 return float(str(value).replace(",", ""))

#             cursor.execute("""
#                 INSERT INTO business_activities
#                 (application_id, line_of_business, num_of_units, capitalization,
#                  gross_sales_essential, gross_sales_nonessential)
#                 VALUES (%s, %s, %s, %s, %s, %s)
#             """, (
#                 application_id,
#                 business_activity.get("line_of_business", ""),
#                 int(business_activity.get("num_of_units", 0)),
#                 clean_number(business_activity.get("capitalization")),
#                 clean_number(business_activity.get("gross_sales_essential")),
#                 clean_number(business_activity.get("gross_sales_nonessential"))
#             ))

#         conn.commit()
#         return jsonify({
#             "status": "success",
#             "message": "Application submitted successfully!",
#             "application_id": application_id,
#             "user_email": user_email
#         }), 200

#     except Exception as e:
#         conn.rollback()
#         print("🔥 ERROR in /submit_application:", str(e))
#         return jsonify({"status": "error", "message": str(e)}), 500

#     finally:
#         cursor.close()
#         conn.close()


# # ---------------- UPLOAD DOCUMENT ROUTE ----------------
# @app.route("/upload_document", methods=["POST"])
# def upload_document():
#     try:
#         application_id = request.form.get("application_id")
#         document_name = request.form.get("document_name")
#         file = request.files.get("file")

#         if not file or not allowed_file(file.filename):
#             return jsonify({"status": "error", "message": "Invalid or missing file"}), 400

#         filename = f"{uuid.uuid4().hex}_{secure_filename(file.filename)}"
#         file_path = os.path.join(UPLOAD_FOLDER, filename)
#         file.save(file_path)

#         conn = get_db_connection()
#         cursor = conn.cursor()
#         cursor.execute("""
#             INSERT INTO uploaded_documents (application_id, document_name, file_path)
#             VALUES (%s, %s, %s)
#         """, (application_id, document_name, filename))
#         conn.commit()

#         return jsonify({"status": "success", "message": "File uploaded successfully!"}), 200

#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 500
#     finally:
#         cursor.close()
#         conn.close()


# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)

