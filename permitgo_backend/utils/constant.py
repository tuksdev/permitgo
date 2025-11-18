# utils/constants.py
import os
from datetime import date, datetime

# --- Database Configuration ---
# This dictionary is essential for db_utils.py
DB_CONFIG = {
    "host": 'localhost',
    "user": 'root',
    "password": '1234',
    "database": 'permitgo'
}

# --- File/Upload Configuration ---
UPLOAD_FOLDER_NAME = 'uploads'
UPLOAD_FOLDER_PATH = os.path.join(os.getcwd(), UPLOAD_FOLDER_NAME)
ALLOWED_EXTENSIONS = {'pdf', 'png', 'jpg', 'jpeg', 'docx', 'doc'}

# --- Payment Gateway Configuration (Xendit) ---
XENDIT_SECRET_KEY = "xnd_development_KZGikQHEoTL6KCLwcvj2wdANG9nzf0fqGBC4QeZ0kpEoW9N85XpOdSBH98ucv"
XENDIT_INVOICE_URL = "https://api.xendit.co/v2/invoices"
# The base URL used for Xendit redirect links
REDIRECT_BASE_URL = "http://192.168.1.100:5000"