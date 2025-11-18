# admin_api.py

from flask import Blueprint, request, jsonify, send_file
import pymysql
import traceback
import io
from datetime import date, datetime, timedelta
import os
import uuid

# FIX: Import all necessary utility functions directly from server.py
from server import (
    get_db_connection, FPDF, 
    fetch_taxpayer_by_id, fetch_lessor_by_application_id, 
    fetch_full_application_details, generate_permit_pdf, 
    fetch_application_data, generate_applicant_report_pdf_logic,
    fetch_top_data, calculate_and_store_taxes, generate_top_pdf_logic,
    save_permit_file
)

# Initialize the Admin Blueprint
# All routes will be prefixed with /admin
admin_bp = Blueprint('admin_api', __name__, url_prefix='/admin')

# ==========================================================
# 🛑 ADMIN DASHBOARD ENDPOINTS 🛑
# ==========================================================

# ✅ ADMIN: GET ALL APPLICATIONS 
@admin_bp.route("/get_all_applications", methods=["GET"])
def get_all_applications():
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        cursor.execute("""
        SELECT
            ba.application_id, 
            ba.status, 
            DATE_FORMAT(ba.created_at, '%%Y-%%m-%%d') AS application_date,
            
            ba.user_id,             
            ba.application_type,    
            
            t.first_name, t.last_name, t.businessName, t.trade_name, t.taxpayer_id,
            ad.business_address, ad.is_rented,
            (SELECT GROUP_CONCAT(lob.line_of_business SEPARATOR ', ') FROM business_activities lob WHERE lob.application_id = ba.application_id) AS line_of_business_list,
            (SELECT SUM(act.capitalization) FROM business_activities act WHERE act.application_id = ba.application_id) AS total_capitalization
        FROM 
            business_applications ba
        JOIN 
            taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN
            application_details ad ON ba.application_id = ad.application_id
        ORDER BY 
            ba.application_date DESC;
    """)
        applications = cursor.fetchall()
        
        for app_data in applications:
            if 'total_capitalization' in app_data and app_data['total_capitalization'] is not None:
                app_data['total_capitalization'] = float(app_data['total_capitalization'])

        return jsonify(applications), 200
    
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to retrieve applications."}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ ADMIN: GENERATE PERMIT (PDF), SAVE RECORD, AND UPDATE STATUS
@admin_bp.route("/certificate/generate/<int:application_id>", methods=["POST"])
def generate_certificate_vbnet(application_id):
    """
    Generates the permit PDF, saves it to disk, records issuance in 
    `issued_permits`, updates application status to 'Completed', and 
    returns the PDF bytes to the client.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        conn.autocommit = False # Start transaction
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # 1. Fetch Core Application Data
        data = fetch_application_data(application_id, cursor)
        if not data:
            conn.rollback()
            return jsonify({"error": "Application data not found."}), 404
        
        # 2. Check if a permit has already been issued (reprint scenario)
        cursor.execute("SELECT permit_number, file_path FROM issued_permits WHERE application_id = %s", (application_id,))
        existing_permit = cursor.fetchone()

        if existing_permit and os.path.exists(existing_permit['file_path']):
            # Case A: Already Issued and file exists - Load and return existing PDF
            file_path_on_server = existing_permit['file_path']
            
            # 3. Update Status to 'Completed' (in case it was 'Payment Received')
            cursor.execute("UPDATE business_applications SET status = 'Completed' WHERE application_id = %s", (application_id,))
            conn.commit()
            
            # Return existing PDF file stream
            return send_file(
                 file_path_on_server,
                 mimetype='application/pdf',
                 as_attachment=False, 
                 download_name=f'Mayor_Permit_{application_id:04}.pdf'
            )
        
        # 4. Generate New PDF Bytes (Case B: New Issue or Reprint with missing file)
        pdf_bytes = generate_permit_pdf(data, application_id) 

        # 5. Save PDF File to Disk
        file_path_on_server = save_permit_file(application_id, pdf_bytes) 
        
        # 6. Determine Permit Details for DB Record
        date_issued = datetime.now()
        expiry_date = (date_issued + timedelta(days=365)).date() # Approx 1 year expiry
        permit_number = f"MP-{application_id:04}-{date_issued.year}" # Custom format
        
        # 7. Insert/Update record into `issued_permits` table
        if existing_permit:
             # If record exists but file was missing, update the path and re-issue date
            cursor.execute("""
                UPDATE issued_permits SET 
                permit_number=%s, file_path=%s, date_issued=%s, expiry_date=%s
                WHERE application_id=%s
            """, (permit_number, file_path_on_server, date_issued, expiry_date, application_id))
        else:
             # Insert new record
            cursor.execute("""
                INSERT INTO issued_permits 
                (application_id, permit_number, file_path, date_issued, expiry_date, issued_by)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (application_id, permit_number, file_path_on_server, date_issued, expiry_date, 'BPLO_Admin_VB'))


        # 8. Update Application Status
        cursor.execute("""
            UPDATE business_applications 
            SET status = 'Completed', permit_issue_date = %s, permit_expiry_date = %s
            WHERE application_id = %s 
            AND status IN ('Payment Received', 'Completed')
        """, (date_issued, expiry_date, application_id))
        
        # 9. Commit transaction
        conn.commit()
        
        # 10. Return PDF bytes to the VB.NET client
        return send_file(
             io.BytesIO(pdf_bytes),
             mimetype='application/pdf',
             as_attachment=False, 
             download_name=f'Mayor_Permit_{application_id:04}.pdf'
        )
        
    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error generating permit: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()


# ✅ NEW: GET DASHBOARD COUNTS ENDPOINT
@admin_bp.route("/get_dashboard_counts", methods=["GET"])
def get_dashboard_counts():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 1. Count ALL Pending Applications (Assuming 'Pending Review', 'Pending Documents')
        cursor.execute("SELECT COUNT(*) FROM business_applications WHERE status LIKE 'Pending%%'")
        pending_count = cursor.fetchone()[0]
        
        # 2. Count New Registrations (Assuming application_type = 'New')
        cursor.execute("SELECT COUNT(*) FROM business_applications WHERE application_type = 'New Application'")
        new_count = cursor.fetchone()[0]
        
        # 3. Count Renewals (Assuming application_type = 'Renewal')
        cursor.execute("SELECT COUNT(*) FROM business_applications WHERE application_type = 'Renewal'")
        renewal_count = cursor.fetchone()[0]
        
        return jsonify({
            "status": "success",
            "pending_applications": pending_count,
            "new_registrations": new_count,
            "renewals": renewal_count
        }), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Failed to retrieve counts: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ ADMIN: GET SINGLE TAXPAYER
@admin_bp.route("/taxpayers/<int:taxpayer_id>", methods=["GET"])
def get_taxpayer(taxpayer_id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        taxpayer = fetch_taxpayer_by_id(taxpayer_id, cursor)
        if taxpayer:
            if 'has_tax_incentive' in taxpayer:
                taxpayer['has_tax_incentive'] = bool(taxpayer['has_tax_incentive'])
            return jsonify(taxpayer), 200
        return jsonify({"status": "error", "message": "Taxpayer not found."}), 404
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if conn: conn.close()

# ✅ ADMIN: UPDATE TAXPAYER
@admin_bp.route("/taxpayers/<int:taxpayer_id>", methods=["PUT"])
def update_taxpayer(taxpayer_id):
    data = request.json
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        has_incentive_int = 1 if data.get("has_tax_incentive") else 0
        
        cursor.execute("""
            UPDATE taxpayers SET 
                last_name=%s, first_name=%s, middle_name=%s, account_number=%s, trade_name=%s, 
                has_tax_incentive=%s, tax_incentive_entity=%s, businessName=%s
            WHERE taxpayer_id=%s
        """, (
            data.get("last_name"), data.get("first_name"), data.get("middle_name"), 
            data.get("account_number"), data.get("trade_name"), 
            has_incentive_int, data.get("tax_incentive_entity"), 
            data.get("businessName"), taxpayer_id
        ))
        conn.commit()
        
        if cursor.rowcount == 0:
            return jsonify({"status": "error", "message": "Taxpayer not found or no changes made."}), 404
            
        return jsonify({"status": "success", "message": f"Taxpayer ID {taxpayer_id} updated."}), 200
    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if conn: conn.close()


# ✅ ADMIN: GET SINGLE LESSOR 
@admin_bp.route("/lessors/<int:application_id>", methods=["GET"])
def get_lessor(application_id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        lessor = fetch_lessor_by_application_id(application_id, cursor)
        
        if lessor:
            if 'monthly_rent' in lessor and lessor['monthly_rent'] is not None:
                 lessor['monthly_rent'] = str(lessor['monthly_rent'])
            return jsonify(lessor), 200
        return jsonify({"status": "error", "message": "Lessor record not found for this application."}), 404
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if conn: conn.close()

# ✅ ADMIN: CREATE OR UPDATE LESSOR
@admin_bp.route("/lessors/<int:application_id>", methods=["PUT", "POST"])
def save_lessor(application_id):
    data = request.json
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT lessor_id FROM lessors WHERE application_id=%s", (application_id,))
        exists = cursor.fetchone()

        monthly_rent = float(data.get("monthly_rent", 0.0) or 0.0)
        lessor_data = (
            data.get("lessor_name"), data.get("lessor_address"), data.get("lessor_email"), 
            data.get("lessor_mobile"), monthly_rent
        )
        
        if exists:
            cursor.execute("""
                UPDATE lessors SET 
                    lessor_name=%s, lessor_address=%s, lessor_email=%s, lessor_mobile=%s, monthly_rent=%s
                WHERE application_id=%s
            """, lessor_data + (application_id,))
            message = "Lessor updated."
        else:
            cursor.execute("""
                INSERT INTO lessors (lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent, application_id)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, lessor_data + (application_id,))
            message = "Lessor record created."
            
        conn.commit()
        return jsonify({"status": "success", "message": message}), 200
        
    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        if conn: conn.close()

# ✅ ADMIN: COMPREHENSIVE REPORT GENERATION (PDF)
@admin_bp.route("/generate_report/<int:application_id>", methods=["GET"])
def generate_applicant_report_route(application_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        data = fetch_full_application_details(application_id, cursor) 

        if not data:
            return jsonify({"error": "Application not found."}), 404
            
        pdf_bytes = generate_applicant_report_pdf_logic(data, application_id) 
        
        return send_file(
            io.BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f'Application_Report_{application_id:04}.pdf'
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": f"Server error during report generation: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

    # ✅ ADMIN: GET LIST OF APPLICATIONS READY FOR RELEASE (VB.NET Queue)
@admin_bp.route("/certificate/queue", methods=["GET"])
def get_certificate_release_queue():
    """Fetches applications with status 'Payment Received' or 'Completed' for release/printing."""
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        # Query applications that are paid or already completed
        cursor.execute("""
            SELECT 
                ba.application_id, 
                CASE 
                    WHEN ba.status = 'Completed' THEN 'Released'
                    ELSE 'Ready for Release'
                END AS status,
                t.first_name, 
                t.last_name, 
                t.businessName,
                pb.or_number, 
                pb.date_paid
            FROM 
                business_applications ba
            JOIN 
                taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            LEFT JOIN
                payments_billing pb ON ba.application_id = pb.application_id 
            WHERE 
                ba.status IN ('Payment Received', 'Completed') 
            ORDER BY 
                pb.date_paid DESC;
        """)
        release_queue = cursor.fetchall()
        
        # Format for VB.NET Consumption
        formatted_queue = []
        for row in release_queue:
            date_paid_str = row['date_paid'].strftime("%m/%d/%Y") if row['date_paid'] else 'N/A'
            
            formatted_queue.append({
                'application_id': row['application_id'],
                'businessName': row['businessName'],
                'ownerName': f"{row['first_name']} {row['last_name']}",
                'or_number': row['or_number'] or 'N/A',
                'date_paid': date_paid_str,
                'status': row['status']
            })
            
        return jsonify(formatted_queue), 200 
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Failed to retrieve release queue: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/certificate/view/<int:application_id>", methods=["GET"])
def view_issued_certificate(application_id):
    """Retrieves the previously generated and stored PDF permit file."""
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # 1. Fetch the file path from the issued_permits table
        cursor.execute("SELECT file_path FROM issued_permits WHERE application_id = %s ORDER BY date_issued DESC LIMIT 1", (application_id,))
        permit_record = cursor.fetchone()

        if not permit_record:
            return jsonify({"error": "Certificate has not been issued yet or record is missing."}), 404
        
        file_path_on_server = permit_record['file_path']
        
        if not os.path.exists(file_path_on_server):
            # If file is missing, try to regenerate it (or prompt admin)
            return jsonify({"error": "Issued file found in database but missing on server disk. Please regenerate."}), 404
            
        # 2. Stream the PDF file back to the client
        return send_file(
             file_path_on_server,
             mimetype='application/pdf',
             as_attachment=False, 
             download_name=f'Mayor_Permit_View_{application_id:04}.pdf'
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": f"Server error retrieving certificate: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()


# # ✅ ADMIN: E-CERTIFICATE GENERATION (PDF)
# @admin_bp.route("/generate_certificate/<int:application_id>", methods=["GET"])
# def generate_certificate_admin(application_id):
#     conn = None
#     cursor = None
#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor(pymysql.cursors.DictCursor)
        
#         data = fetch_application_data(application_id, cursor)

#         if not data:
#             return jsonify({"error": "Application not found."}), 404
            
#         if data.get('status') != 'Approved':
#             return jsonify({"error": f"Application ID {application_id} is not Approved. Current status: {data.get('status')}"}), 403

#         pdf_bytes = generate_permit_pdf(data, application_id) 
        
#         return send_file(
#             io.BytesIO(pdf_bytes),
#             mimetype='application/pdf',
#             as_attachment=True,
#             download_name=f'Mayor_Permit_{application_id:04}.pdf'
#         )

#     except Exception as e:
#         traceback.print_exc()
#         return jsonify({"error": f"Server error during certificate generation: {str(e)}"}), 500
#     finally:
#         if cursor: cursor.close()
#         if conn: conn.close()

# ✅ ADMIN: GET FULL APPLICATION DETAILS BY ID
@admin_bp.route("/get_application_details/<int:application_id>", methods=["GET"])
def get_application_details(application_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        # This calls the utility function in server.py
        data = fetch_full_application_details(application_id, cursor) 
        
        if not data:
            return jsonify({"status": "error", "message": "Application not found."}), 404
        
        # Convert any dates to string for JSON serialization
        for key, value in data.items():
             if isinstance(value, (date, datetime)):
                 data[key] = value.isoformat()
                 
        return jsonify({"status": "success", "data": data}), 200
    
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ ADMIN: DOWNLOAD DOCUMENT CONTENT
@admin_bp.route("/download_document/<int:application_id>/<string:document_name>", methods=["GET"])
def download_document(application_id, document_name):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT file_path 
            FROM uploaded_documents 
            WHERE application_id = %s AND file_path LIKE CONCAT('%%', %s)
            LIMIT 1
        """, (application_id, document_name))
        
        result = cursor.fetchone()
        
        if not result:
            return jsonify({"status": "error", "message": "Document record not found."}), 404
        
        file_path_on_server = result[0] 
        
        if not os.path.exists(file_path_on_server):
            return jsonify({"status": "error", "message": "File not found on server disk."}), 404
            
        mime_type = 'application/octet-stream'
        filename_part = os.path.basename(file_path_on_server).lower()
        
        if filename_part.endswith(('.png', '.jpg', '.jpeg')):
            mime_type = 'image/jpeg'
        elif filename_part.endswith('.pdf'):
            mime_type = 'application/pdf'
            
        return send_file(
            file_path_on_server,
            mimetype=mime_type,
            as_attachment=False 
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/get_application_documents/<int:application_id>", methods=["GET"])
def get_application_documents(application_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        cursor.execute("""
            SELECT
                document_id,
                req_code,  
                document_purpose, 
                file_path,      
                uploaded_at     
            FROM 
                uploaded_documents
            WHERE 
                application_id = %s
            ORDER BY 
                uploaded_at DESC;
        """, (application_id,))
        
        documents = cursor.fetchall()
        
        for doc in documents:
             if isinstance(doc.get('uploaded_at'), (date, datetime)):
                 doc['uploaded_at'] = doc['uploaded_at'].isoformat()
                 
        return jsonify({"status": "success", "documents": documents}), 200
    
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error fetching documents: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/update_application_status/<int:application_id>", methods=["PUT"])
def update_application_status(application_id):
    data = request.get_json()
    new_status = data.get("status") 
    
    if application_id <= 0:
        return jsonify({"status": "error", "message": "Invalid application status provided."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE business_applications 
            SET status = %s 
            WHERE application_id = %s
        """, (new_status, application_id))
        
        conn.commit()
        
        if cursor.rowcount == 0:
            # This handles the case where the application ID does not exist
            return jsonify({"status": "error", "message": "Application ID not found."}), 404
            
        return jsonify({"status": "success", "message": f"Application status updated to {new_status}."}), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error during status update: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()



# @admin_bp.route("/get_uploaded_by_purpose/<int:application_id>/<string:purpose>", methods=["GET"])
# def get_uploaded_by_purpose(application_id, purpose):

#     if purpose.lower() != "renewal":
#         return jsonfy({
#             "status": "error", 
#             "message": "Invalid purpose. Only 'Renewal' is supported."
#         }), 400
    
#     db_purpose = "Renewal"
#     conn = None
#     cursor = None
#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
#         cursor.execute("""
#             SELECT
#                 document_id, document_name, document_purpose, file_path, uploaded_at     
#             FROM 
#                 uploaded_documents
#             WHERE 
#                 application_id = %s AND document_purpose = %s
#             ORDER BY 
#                 uploaded_at DESC;
#         """, (application_id, db_purpose)) 
        
#         documents = cursor.fetchall()
        
#         for doc in documents:
#              if isinstance(doc.get('uploaded_at'), (date, datetime)):
#                  doc['uploaded_at'] = doc['uploaded_at'].isoformat()
                 
#         return jsonify({"status": "success", "documents": documents}), 200
    
#     except Exception as e:
#         traceback.print_exc()
#         return jsonify({"status": "error", "message": f"Server error fetching documents: {str(e)}"}), 500
#     finally:
#         if cursor: cursor.close()
#         if conn: conn.close()

@admin_bp.route("/get_uploaded_by_purpose/<int:application_id>/<string:purpose>", methods=["GET"])
def get_uploaded_by_purpose(application_id, purpose):

    if purpose.lower() != "renewal":
        return jsonify({ 
            "status": "error", 
            "message": "Invalid purpose. Only 'Renewal' is supported."
        }), 400
    
    db_purpose = "Renewal"
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        cursor.execute("""
            SELECT
                document_id, req_code, document_purpose, file_path, uploaded_at      
            FROM 
                uploaded_documents
            WHERE 
                application_id = %s AND document_purpose = %s
            ORDER BY 
                uploaded_at DESC;
        """, (application_id, db_purpose)) 
        
        documents = cursor.fetchall()
        
        for doc in documents:
            uploaded_date = doc.get('uploaded_at')
            if uploaded_date is not None and isinstance(uploaded_date, (date, datetime)):
                doc['uploaded_at'] = uploaded_date.isoformat()
            elif uploaded_date is not None:
                
                doc['uploaded_at'] = str(uploaded_date)
                
        return jsonify({"status": "success", "documents": documents}), 200
    
    except Exception as e:
        traceback.print_exc()
        
        return jsonify({"status": "error", "message": f"Server error fetching documents: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
        
@admin_bp.route("/get_renewal_list", methods=["GET"])
def get_renewal_list():
   
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        cursor.execute("""
            SELECT
                ba.application_id, ba.status, DATE_FORMAT(ba.application_date, '%%Y-%%m-%%d') AS application_date,
                ba.user_id, ba.application_type, t.businessName, t.trade_name, t.first_name, t.last_name
            FROM 
                business_applications ba
            JOIN 
                taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            WHERE 
                ba.application_type = 'Renewal' 
            ORDER BY 
                ba.application_date DESC;
        """,)
        applications = cursor.fetchall()
        
        
        return jsonify(applications), 200
    
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to retrieve renewal list."}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/get_renewal_details/<int:application_id>", methods=["GET"])
def get_renewal_details(application_id):
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 

        cursor.execute("""
            SELECT
                ba.*,
                t.last_name, t.first_name, t.middle_name, t.account_number, t.trade_name, t.has_tax_incentive, t.tax_incentive_entity, t.businessName,
                ad.business_address, ad.postal_code, ad.owner_address, ad.owner_email, ad.owner_mobile, ad.emergency_contact, ad.emergency_email, ad.emergency_mobile, ad.business_area, ad.employees_total, ad.employees_with_lgu, ad.is_rented,
                bact.line_of_business, bact.num_of_units, bact.capitalization, bact.gross_sales_essential, bact.gross_sales_nonessential,
                l.lessor_name, l.lessor_address, l.lessor_email, l.lessor_mobile, l.monthly_rent
            FROM
                business_applications ba
            JOIN
                taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            LEFT JOIN
                application_details ad ON ba.application_id = ad.application_id
            LEFT JOIN
                business_activities bact ON ba.application_id = bact.application_id
            LEFT JOIN
                lessors l ON ba.application_id = l.application_id
            WHERE
                ba.application_id = %s
                AND ba.application_type = 'Renewal';
        """, (application_id,))
        
        application_details = cursor.fetchone()

        if not application_details:
            return jsonify({"status": "error", "message": "Renewal application not found."}), 404 
        
        data = application_details
        
        if 'has_tax_incentive' in data and data['has_tax_incentive'] is not None:
            data['has_tax_incentive'] = bool(data['has_tax_incentive'])
       
       
        lessor_data = {
            'lessor_name': data.pop('lessor_name', None),
            'lessor_address': data.pop('lessor_address', None),
            'lessor_email': data.pop('lessor_email', None),
            'lessor_mobile': data.pop('lessor_mobile', None),
            'monthly_rent': data.pop('monthly_rent', None),
        }
        # If all lessor fields are null, set lessor to None/null
        data['lessor'] = lessor_data if any(lessor_data.values()) else None 
        
        # Extract business activities data and nest it (assuming max 1 primary activity for simplicity)
        activity_data = {
            'line_of_business': data.pop('line_of_business', None),
            'num_of_units': data.pop('num_of_units', None),
            'capitalization': data.pop('capitalization', None),
            'gross_sales_essential': data.pop('gross_sales_essential', None),
            'gross_sales_nonessential': data.pop('gross_sales_nonessential', None),
        }

        if activity_data['line_of_business']:
             data['activities'] = [activity_data]
        else:
             data['activities'] = []

        # Convert any remaining dates to string for JSON serialization
        for key, value in data.items():
            if isinstance(value, (date, datetime)):
                data[key] = value.isoformat()
        # -----------------------------------------------

        return jsonify({"status": "success", "data": data}), 200
    
    except Exception as e:
        # Log the traceback for debugging
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ ADMIN: GET APPLICATIONS FOR TREASURY OFFICE (Updated)
@admin_bp.route("/get_applications_for_treasury", methods=["GET"])
def get_applications_for_treasury():
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        cursor.execute("""
            SELECT
                ba.application_id, 
                
                -- CRITICAL STATUS MAPPING for VB.NET Dashboard Display
                CASE 
                   
                    WHEN ba.status IN ('Approved', 'Pending Review') THEN 'Ready for Tax Assessment'  
                    WHEN ba.status = 'Ready for Payment' THEN 'Pay to the Treasury Office' 
                    WHEN ba.status = 'Payment Received' THEN 'Payment Confirmed'
                    ELSE ba.status 
                END AS status, 
                
                ba.application_type,
                t.first_name, t.last_name, t.businessName, t.trade_name,
                
                -- --- PAYMENT STATUS CHECK (for 'Paid Status' column) ---
                pb.or_number,
                pb.date_paid,
                CASE 
                    WHEN pb.or_number IS NOT NULL AND ba.status = 'Payment Received' THEN 'PAID'
                    WHEN ba.status = 'Ready for Payment' THEN 'AWAITING PAYMENT'
                    ELSE 'UNPAID'
                END AS payment_status   
            FROM 
                business_applications ba
            JOIN 
                taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            LEFT JOIN
                payments_billing pb ON ba.application_id = pb.application_id 
            WHERE 
                -- Filter only Treasury workflow statuses
                ba.status IN ('Approved', 'Pending Review', 'Ready for Payment', 'Payment Received') 
            ORDER BY 
                ba.application_date ASC;
        """)
        applications = cursor.fetchall()
        
        return jsonify(applications), 200 
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to retrieve Treasury applications."}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# @admin_bp.route("/get_applications_for_treasury", methods=["GET"])
# def get_applications_for_treasury():
#     conn = None 
#     cursor = None
#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
#         cursor.execute("""
#             SELECT
#                 ba.application_id, ba.status, ba.application_type,
#                 t.first_name, t.last_name, t.businessName, t.trade_name,
                
#                 -- --- PAYMENT STATUS CHECK (for VB.NET list) ---
#                 pb.or_number,
#                 pb.date_paid,
#                 CASE 
#                     WHEN pb.or_number IS NOT NULL AND ba.status = 'Payment Received' THEN 'PAID'
#                     WHEN ba.status = 'Ready for Payment' THEN 'AWAITING PAYMENT'
#                     ELSE 'UNPAID'
#                 END AS payment_status
                
#             FROM 
#                 business_applications ba
#             JOIN 
#                 taxpayers t ON ba.taxpayer_id = t.taxpayer_id
#             LEFT JOIN
#                 payments_billing pb ON ba.application_id = pb.application_id -- Retrieve payment/audit data
#             WHERE 
#                 ba.status IN ('Pending Review', 'Ready for Payment', 'Payment Received')
#             ORDER BY 
#                 ba.application_date ASC;
#         """)
#         applications = cursor.fetchall()
        
#         return jsonify(applications), 200
    
#     except Exception as e:
#         traceback.print_exc()
#         return jsonify({"status": "error", "message": "Failed to retrieve Treasury applications."}), 500
#     finally:
#         if cursor: cursor.close()
#         if conn: conn.close()


# ✅ TREASURY: TAX ASSESSMENT AND BILLING (NEW ROUTE)
@admin_bp.route("/assess_and_bill/<int:application_id>", methods=["POST"])
def assess_and_bill(application_id):
    data = request.get_json() 
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        conn.autocommit = False
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        final_bill_data = calculate_and_store_taxes(application_id, data, cursor) 
        cursor.execute("UPDATE business_applications SET status = 'Approved' WHERE application_id = %s", (application_id,))
        
        conn.commit()
        
        return jsonify({
            "status": "success", 
            "message": "Tax assessment complete. Application is now Ready for Payment.",
            "total_due": str(final_bill_data['total_annual_due'])
        }), 200
        
    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Tax assessment failed: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ TREASURY: GENERATE TAX ORDER OF PAYMENT (TOP) PDF
@admin_bp.route("/generate_top/<int:application_id>", methods=["GET"])
def generate_top_route(application_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        data = fetch_top_data(application_id, cursor) 

        if not data:
            return jsonify({"error": "Tax Assessment data not found. Run assessment first."}), 404
            
        pdf_bytes = generate_top_pdf_logic(data) 
        
        return send_file(
            io.BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=False, 
            download_name=f'Tax_Order_of_Payment_{application_id:04}.pdf'
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": f"Server error during TOP generation: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
        
# ✅ TREASURY: CONFIRM PAYMENT STATUS AND RECORD OR NUMBER
@admin_bp.route("/update_payment_status/<int:application_id>", methods=["PUT"])
def update_payment_status(application_id):
    data = request.get_json()
    status_from_client = 'Completed'
    or_number = data.get("or_number")
    user_id = data.get("confirmed_by_user_id") 
    
    if status_from_client != 'Payment Received' or not or_number or not user_id:
        return jsonify({"status": "error", "message": "Invalid status, missing OR number, or missing admin user ID."}), 400
    
    new_db_status = 'Completed'

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 1. Update the status in business_applications
        rows_updated = cursor.execute("""
            UPDATE business_applications 
            SET status = %s 
            WHERE application_id = %s AND status = 'Approved'
        """, (status_from_client, application_id))

        # Check if the application was actually found and updated
        if rows_updated == 0:
            conn.rollback()
            return jsonify({"status": "error", "message": "Application not found or status was incorrect (must be 'Approved')."}), 404
        
        # 2. Record the OR number in the payments_billing table
        cursor.execute("""
            UPDATE payments_billing
            SET or_number = %s, date_paid = CURDATE(), confirmed_by_user_id = %s
            WHERE application_id = %s
        """, (or_number, user_id, application_id))

        conn.commit()
        
        if cursor.rowcount == 0:
            return jsonify({"status": "error", "message": "Application not found or status was incorrect."}), 404
            
        return jsonify({"status": "success", "message": "Payment confirmed. Status updated to Payment Received."}), 200
        
    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error during payment confirmation: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/get_ready_for_release", methods=["GET"])
def get_ready_for_release():
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        cursor.execute("""
            SELECT
                ba.application_id, 
                ba.application_type,
                t.first_name, 
                t.last_name, 
                t.businessName, 
                pb.or_number, 
                pb.date_paid,
                ba.status
            FROM 
                business_applications ba
            JOIN 
                taxpayers t ON ba.taxpayer_id = t.taxpayer_id
            LEFT JOIN
                payments_billing pb ON ba.application_id = pb.application_id 
            WHERE 
                ba.status = 'Payment Received' -- Only fetch apps where payment is confirmed
            ORDER BY 
                pb.date_paid DESC;
        """)
        release_queue = cursor.fetchall()
        
        return jsonify(release_queue), 200 
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to retrieve release queue."}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@admin_bp.route("/notification_categories", methods=["GET"])
def get_notification_categories():
    conn = get_db_connection()
    cursor = conn.cursor(pymysql.cursors.DictCursor)

    cursor.execute("SELECT id, name, message_template FROM notification_categories")
    categories = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify(categories), 200

@admin_bp.route("/send_notification", methods=["POST"])
def send_notification():
    data = request.get_json()
    user_id = data.get("user_id")
    category_id = data.get("category_id")
    custom_message = data.get("custom_message", "")

    if not user_id or not category_id:
        return jsonify({"status": "error", "message": "user_id and category_id are required"}), 400


    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            INSERT INTO notifications (user_id, category_id, custom_message)
            VALUES (%s, %s, %s)
        """, (user_id, category_id, custom_message))
        conn.commit()
        inserted_id = cursor.lastrowid
        return jsonify({"status": "success", "id": inserted_id}), 200
    except Exception as e:
        conn.rollback()
        import traceback; traceback.print_exc()
        return jsonify({"status":"error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()





# # --- ADMIN: TAX ASSESSMENT AND BILLING ENDPOINT ---
# @admin_bp.route("/assess_and_bill/<int:application_id>", methods=["POST"])
# def assess_and_bill(application_id):
#     conn = None
#     cursor = None
#     try:
#         conn = get_db_connection()
#         conn.autocommit = False
#         cursor = conn.cursor()
        
#         # --- 1. Perform Tax Calculation Logic ---
#         # This function (to be created below) deletes old fees, calculates new ones, 
#         # and inserts data into application_fees and payments_billing.
#         final_bill_data = calculate_and_store_taxes(application_id, cursor)
        
#         if not final_bill_data:
#             conn.rollback()
#             return jsonify({"status": "error", "message": "Failed to calculate tax: Application data missing."}), 404

#         # --- 2. Update Application Status ---
#         # Change status to indicate it is ready for payment (BPLO Step 8/7 complete)
#         cursor.execute("UPDATE business_applications SET status = 'Ready for Payment' WHERE application_id = %s", (application_id,))
        
#         conn.commit()
        
#         return jsonify({
#             "status": "success", 
#             "message": "Tax assessment complete. Application status updated.",
#             "total_due": str(final_bill_data['total_annual_due'])
#         }), 200
        
#     except Exception as e:
#         if conn: conn.rollback()
#         traceback.print_exc()
#         return jsonify({"status": "error", "message": f"Tax assessment failed: {str(e)}"}), 500
#     finally:
#         if cursor: cursor.close()
#         if conn: conn.close()
# # NOTE: This is a placeholder structure for the calculation logic. 
# # Actual tax formulas (rates, tiers) must be defined here.

# def calculate_and_store_taxes(application_id, cursor):
    
#     # 1. DELETE existing records (ensuring clean assessment)
#     cursor.execute("DELETE FROM application_fees WHERE application_id = %s", (application_id,))
#     cursor.execute("DELETE FROM payments_billing WHERE application_id = %s", (application_id,))

#     # 2. FETCH essential business data (capitalization, gross sales, etc.)
#     # (Use a JOIN query here)
    
#     # --- 3. CORE TAX CALCULATION (Simplified example) ---
    
#     # Example 3a: Business Tax (based on Gross Sales)
#     annual_gross = 500000.00 # Placeholder for fetched value
#     business_tax = annual_gross * 0.005  # Example 0.5% rate
    
#     # Insert business tax line item
#     cursor.execute("""
#         INSERT INTO application_fees (application_id, fee_code, fee_description, tax_base, annual_due, fee_type)
#         VALUES (%s, 'BT-01', 'Business Tax on Gross Sales', %s, %s, 'Tax')
#     """, (application_id, annual_gross, business_tax))
    
#     # Example 3b: Regulatory Fees (Fixed Permit Fee)
#     permit_fee = 150.00
#     cursor.execute("""
#         INSERT INTO application_fees (application_id, fee_code, fee_description, annual_due, fee_type)
#         VALUES (%s, 'MP-01', 'Mayor\'s Permit Fee', 0.00, %s, 'Regulatory')
#     """, (application_id, permit_fee))
    
#     # --- 4. CALCULATE FINAL BILLING ---
#     cursor.execute("SELECT SUM(annual_due) FROM application_fees WHERE application_id = %s", (application_id,))
#     total_annual_due = cursor.fetchone()[0] or 0.0
    
#     # Insert final summary into payments_billing
#     cursor.execute("""
#         INSERT INTO payments_billing (application_id, total_annual_due, total_tax_base, total_qtr_due, total_business_tax, due_date)
#         VALUES (%s, %s, 0, %s, %s, CURDATE())
#     """, (application_id, total_annual_due, total_annual_due, business_tax))
    
#     # Return the final summary needed for the endpoint response
#     return {'total_annual_due': total_annual_due}
