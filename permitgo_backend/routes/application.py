# routes/applications.py
from flask import Blueprint, request, jsonify
from permitgo_backend.services.db_utils import get_db_connection
from permitgo_backend.services.app_services import fetch_application_data_details # Import service functions
from datetime import date, datetime
import pymysql.cursors
import traceback
from permitgo_backend.services.app_services import fetch_full_application_details # Need the full details function

app_bp = Blueprint('applications', __name__)

@app_bp.route("/submit", methods=["POST"])
def submit_application():
    data = request.get_json()
    user_id = data.get("user_id")

    if not user_id:
        return jsonify({"status": "error", "message": "Missing user_id."}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # --- 1. Insert taxpayer --- (Your original Step 1)
        # ... (Taxpayer insertion logic) ...
        cursor.execute("""
             INSERT INTO taxpayers (first_name, last_name, trade_name, businessName)
             VALUES (%s, %s, %s, %s)
        """, (data.get("first_name", ""), data.get("last_name", ""), data.get("trade_name", ""), data.get("businessName", "")))
        taxpayer_id = cursor.lastrowid
        
        # --- 2. Insert business application --- (Your original Step 2)
        cursor.execute("""
             INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date, tin_no)
             VALUES (%s, %s, %s, %s, %s)
        """, (user_id, taxpayer_id, data.get("application_type", ""), data.get("application_date", str(date.today())), data.get("tin_no", "")))
        application_id = cursor.lastrowid
        
     # --- 3. Insert application details (Address, Contact, Employees) --- (Your original Step 3)
        is_rented_val = data.get("is_rented", 0) # Assumed 0/1 integer
        is_rented_db_value = 'Rented' if is_rented_val == 1 else 'Owned'
        business_area_val = float(data.get("business_area", 0.0) or 0.0)

        cursor.execute("""
            INSERT INTO application_details (application_id, business_address, postal_code, owner_address,
                                             owner_email, owner_mobile, emergency_contact, emergency_email,
                                             emergency_mobile, business_area, employees_total, employees_with_lgu,
                                             is_rented)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            application_id, data.get("business_address", ""), data.get("postal_code", ""), 
            data.get("owner_address", ""), data.get("owner_email", ""), data.get("owner_mobile", ""),
            data.get("emergency_contact", ""), data.get("emergency_email", ""), 
            data.get("emergency_mobile", ""), business_area_val, data.get("employees_total", 0),
            data.get("employees_with_lgu", 0), is_rented_db_value
        ))

        # --- 4. Insert lessor info (if rented) --- (Your original Step 4)
        if is_rented_val == 1:
            monthly_rent_val = float(data.get("monthly_rent", 0.0) or 0.0)
            cursor.execute("""
                INSERT INTO lessors (application_id, lessor_name, lessor_address, lessor_email,
                                     lessor_mobile, monthly_rent)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                application_id, data.get("lessor_name", ""), data.get("lessor_address", ""), 
                data.get("lessor_email", ""), data.get("lessor_mobile", ""), monthly_rent_val
            ))

        # --- 5. Insert business activities --- (Your original Step 5)
        cursor.execute("""
            INSERT INTO business_activities (application_id, line_of_business, num_of_units,
                                             capitalization, gross_sales_essential, gross_sales_nonessential)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            application_id, data.get("line_of_business", ""), int(data.get("num_of_units", 0) or 0), 
            float(data.get("capitalization", 0.0) or 0.0), 
            float(data.get("gross_sales_essential", 0.0) or 0.0),
            float(data.get("gross_sales_nonessential", 0.0) or 0.0) # Assuming the key is corrected here
        ))

        conn.commit()
        return jsonify({"status": "success", "message": "Application submitted successfully!", "application_id": application_id}), 201

    except Exception as e:
        if conn: conn.rollback()
        print(f"❌ Database error during submission: {traceback.format_exc()}")
        return jsonify({"status": "error", "message": f"Submission failed due to server error. Details: {str(e)}"}), 500
    finally:
        if conn: conn.close()

@app_bp.route("/renewal", methods=["POST"])
def renewal():
    # Placeholder for renewal logic (you have a submit_renewal_v2, which is better used)
    # This route should be updated to match submit_renewal_v2 from your monolithic code
    return jsonify({"status": "error", "message": "Use /submit_renewal instead of /renewal"}), 400


@app_bp.route("/user_applications/<string:user_id>", methods=["GET"])
def get_user_applications(user_id):
    """Get all previous applications for a user."""
    conn = None
    try:
        # NOTE: Use DictCursor here to match your logic
        conn = get_db_connection(dict_cursor=True)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                ba.application_id, ba.application_type, ba.application_date, ba.status,
                ba.permit_issue_date, ba.permit_expiry_date,
                t.trade_name, t.businessName, t.first_name, t.last_name, 
                ad.business_address
            FROM business_applications ba
            JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            LEFT JOIN application_details ad ON ba.application_id = ad.application_id
            WHERE ba.user_id = %s
            ORDER BY ba.application_date DESC
        """, (user_id,))
        
        applications = cursor.fetchall()
        
        # Convert dates to strings for JSON serialization
        for app in applications:
            for key, value in app.items():
                if isinstance(value, (date, datetime)):
                    app[key] = value.isoformat()
                    
        return jsonify({"status": "success", "data": applications}), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    finally:
        if conn: conn.close()
        
@app_bp.route("/get_last_application_details/<string:user_id>", methods=["GET"])
def get_last_application_details(user_id):
    """
    CRITICAL RENEWAL ENDPOINT: Fetches ALL data needed to pre-fill the renewal forms 
    from the user's most recent application.
    """
    conn = None
    try:
        # Use DictCursor for fetching dictionary results
        conn = get_db_connection(dict_cursor=True)
        cursor = conn.cursor()
        
        # 1. Find the ID of the last application
        cursor.execute("""
            SELECT application_id
            FROM business_applications ba
            WHERE ba.user_id = %s
            ORDER BY ba.application_date DESC
            LIMIT 1
        """, (user_id,))
        result = cursor.fetchone()
        
        if not result:
            return jsonify({"status": "error", "message": "No previous application found for renewal."}), 404
            
        application_id = result['application_id']
        
        # 2. Fetch the comprehensive data set using utility
        # NOTE: fetch_full_application_details must be available and correctly implemented
        full_data = fetch_full_application_details(application_id, cursor) 
        
        if full_data:
             # Flatten activity data for pre-fill
             if full_data.get('activities'):
                 # Merge the first activity's details into the top level
                 full_data.update(full_data['activities'][0]) 
             
             full_data.pop('activities', None) 
             
             return jsonify({"status": "success", "data": full_data}), 200
        
        return jsonify({"status": "error", "message": "Application details incomplete."}), 404
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error fetching renewal data: {str(e)}"}), 500
    finally:
        if conn: conn.close()