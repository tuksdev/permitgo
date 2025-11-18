# server.py

import os
import io
import traceback
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql
from datetime import date, datetime
import json

# --- IMPORT UTILITIES AND CONFIGURATION ---
# NOTE: You must have an empty __init__.py in the routes/ and services/ folders
from permitgo_backend.routes.auth import auth_bp
from permitgo_backend.routes.application import app_bp
from permitgo_backend.routes.payments import payment_bp
from permitgo_backend.routes.documents import doc_bp 

# --- UTILITIES MOVED FROM MONOLITHIC FILE ---

# 1. Database Configuration
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "permitgo"
}

def get_db_connection(dict_cursor=False):
    """Returns a new DB connection, optionally with a DictCursor."""
    cursor_type = pymysql.cursors.DictCursor if dict_cursor else pymysql.cursors.Cursor
    return pymysql.connect(cursorclass=cursor_type, **DB_CONFIG)


# 2. Xendit Configuration (Used in payments.py)
XENDIT_SECRET_KEY = "xnd_development_KZGikQHEoTL6KCLwcvj2wdANG9nzf0fqGBC4QeZ0kpEoW9N85XpOdSBH98ucv"
XENDIT_INVOICE_URL = "https://api.xendit.co/v2/invoices"
# Use the IP defined in your monolithic file
REDIRECT_BASE_URL = "http://192.168.1.100:5000" 


# 3. PDF/Document Handlers (Move these to service/pdf_generator.py and utils/file_handler.py)
# NOTE: The FPDF class fallback is heavy. We'll leave it here temporarily.
try:
    from fpdf import FPDF, HTMLMixin
except ImportError:
    class FPDF:
        def __init__(self, *args, **kwargs): pass
        def add_page(self): pass
        def output(self, *args): return b''


# --- FLASK APP INITIALIZATION ---
app = Flask(__name__)
CORS(app)

# Upload folder setup (Move to utils/constants.py or use the global variable)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


# --- REGISTER BLUEPRINTS ---
# Your original routes are now mapped under these prefixes
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(app_bp, url_prefix='/api/applications')
app.register_blueprint(payment_bp, url_prefix='/api/payments')
app.register_blueprint(doc_bp, url_prefix='/api/documents')


# --- REMAINING MONOLITHIC UTILITIES/ROUTES (KEEP FOR ORCHESTRATION) ---

@app.route("/")
def home():
    return {"message": "Flask backend is running!"}

# You must also define or import all the utility functions you use in your application, 
# such as fetch_full_application_details, fetch_taxpayer_by_id, and generate_permit_pdf,
# but those belong in the /services folder (app_service.py, pdf_generator.py).

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)