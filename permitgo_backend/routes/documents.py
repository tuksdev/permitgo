# routes/documents.py

from flask import Blueprint, request, jsonify, send_file, current_app
from permitgo_backend.services.db_utils import get_db_connection
from permitgo_backend.services.pdf_generator import generate_permit_pdf # Assumed service function
from permitgo_backend.services.app_services import fetch_full_application_details # Assumed service function
from werkzeug.utils import secure_filename
from permitgo_backend.utils.file_handler import allowed_file
import os
import io
import traceback
import pymysql.cursors

doc_bp = Blueprint('documents', __name__)

# ✅ UPLOAD DOCUMENT
@doc_bp.route('/upload', methods=['POST'])
def upload_document():
    try:
        application_id = request.form.get('application_id')
        document_code = request.form.get('document_name')
        
        if not application_id or not document_code:
            return jsonify({"status": "error", "message": "Missing application ID or document code."}), 400

        if 'document' not in request.files:
            return jsonify({"status": "error", "message": "No file part."}), 400
            
        file = request.files['document']

        if file.filename == '' or not allowed_file(file.filename):
            return jsonify({"status": "error", "message": "No selected file or file type not allowed."}), 400

        # Secure and Save File
        original_filename = secure_filename(file.filename)
        # Use current_app.config for Flask app settings
        upload_dir = current_app.config['UPLOAD_FOLDER'] 
        os.makedirs(upload_dir, exist_ok=True)
        
        filename = f"{application_id}_{document_code}_{original_filename}"
        file_path_on_server = os.path.join(upload_dir, filename)
        file.save(file_path_on_server)

        # Record Metadata in MySQL
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO uploaded_documents (application_id, document_name, file_path)
                VALUES (%s, %s, %s)
            """, (application_id, document_code, file_path_on_server))
            conn.commit()
        
        return jsonify({"status": "success", "message": f"{document_code} uploaded successfully"}), 200

    except Exception as e:
        print(f"Server Error during document upload: {traceback.format_exc()}")
        return jsonify({"status": "error", "message": f"Server error processing upload: {str(e)}"}), 500
    finally:
        if 'conn' in locals() and conn: conn.close()

# ✅ USER: DOWNLOAD CERTIFICATE
@doc_bp.route("/download_permit/<int:application_id>", methods=["GET"])
def download_permit_user(application_id):
    conn = None
    try:
        conn = get_db_connection(dict_cursor=True)
        cursor = conn.cursor()
        
        # 1. Fetch data (Delegated to service)
        # Assuming fetch_full_application_details is accessible and returns DictCursor data
        data = fetch_full_application_details(application_id, cursor) 

        if not data:
            return jsonify({"error": "Application not found."}), 404
            
        if data.get('status') != 'Approved':
             return jsonify({"error": f"Application ID {application_id} is not Approved."}), 403

        # 2. Generate PDF (Delegated to service)
        pdf_bytes = generate_permit_pdf(data, application_id)
        
        # 3. Send file
        return send_file(
            io.BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f'Mayor_Permit_{application_id:04}.pdf'
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": f"Server error during certificate generation: {str(e)}"}), 500
    finally:
        if conn: conn.close()