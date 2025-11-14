# server.py

import json
import uuid
import os
import io
import traceback
from flask import Flask, request, jsonify, send_file
import requests
from flask_cors import CORS
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql.cursors
from datetime import date, datetime, timedelta
from fpdf import FPDF as FPDF2 # Keep this for the conditional import logic check
import base64

# --- Conditional FPDF Import (Must be at the top) ---
try:
    from fpdf import FPDF, HTMLMixin
except ImportError:
    print("WARNING: fpdf2 not installed. Certificate generation will fail.")
    class FPDF:
        def __init__(self, *args, **kwargs): pass
        def add_page(self): pass
        def set_xy(self, *args): pass
        def set_font(self, *args): pass
        def multi_cell(self, *args): pass
        def cell(self, *args): pass
        def ln(self, *args): pass
        def output(self, *args): return b''

# --- APP SETUP ---
app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
ALLOWED_EXTENSIONS = {'pdf', 'png', 'jpg', 'jpeg', 'docx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# --- SHARED UTILITIES (Needed by Admin API) ---
db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "databse_permitgo"
}

def get_db_connection():
    return pymysql.connect(**db_config)

# Xendit Configuration
XENDIT_SECRET_KEY = "xnd_development_KZGikQHEoTL6KCLwcvj2wdANG9nzf0fqGBC4QeZ0kpEoW9N85XpOdSBH98ucv"
XENDIT_INVOICE_URL = "https://api.xendit.co/v2/invoices"

# Utility for fetching single Taxpayer data
def fetch_taxpayer_by_id(taxpayer_id, cursor):
    """Fetches a single taxpayer record by their ID."""
    cursor.execute("""
        SELECT taxpayer_id, last_name, first_name, middle_name, account_number, 
               trade_name, has_tax_incentive, tax_incentive_entity, businessName
        FROM taxpayers 
        WHERE taxpayer_id = %s
    """, (taxpayer_id,))
    return cursor.fetchone()

# Utility for fetching single Lessor data
def fetch_lessor_by_application_id(application_id, cursor):
    """Fetches a single lessor record using the foreign key application_id."""
    cursor.execute("""
        SELECT lessor_id, lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent
        FROM lessors 
        WHERE application_id = %s
    """, (application_id,))
    return cursor.fetchone()

# Utility for fetching core application data (Used by Permit Generation)
def fetch_application_data(application_id, cursor):
    """Fetches core data needed for permit generation (name, business name, dates, status)."""
    cursor.execute("""
        SELECT
            ba.application_id, ba.status, ba.application_type, ba.application_date,
            ba.tin_no, ba.mode_of_payment, ba.business_type, ba.amendment_from, ba.amendment_to,
            ba.permit_issue_date, ba.permit_expiry_date,
            t.first_name, t.last_name, t.middle_name, t.trade_name, t.businessName, 
            ad.business_address
        FROM 
            business_applications ba
        JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN application_details ad ON ba.application_id = ad.application_id
        WHERE 
            ba.application_id = %s;
    """, (application_id,))
    return cursor.fetchone()

# Utility for fetching full application data (Used by Renewal and Admin Report)
def fetch_full_application_details(application_id, cursor):
    """Fetches all nested details for a comprehensive report."""
    cursor.execute("""
        SELECT
            ba.application_id, ba.status, ba.application_type, ba.application_date,
            ba.tin_no, ba.mode_of_payment, ba.business_type, ba.amendment_from, ba.amendment_to,
            ba.permit_issue_date, ba.permit_expiry_date,
            t.first_name, t.last_name, t.middle_name, t.trade_name, t.businessName, 
            t.account_number, t.has_tax_incentive, t.tax_incentive_entity,
            ad.business_address, ad.postal_code, ad.owner_address, ad.owner_email, ad.owner_mobile, 
            ad.emergency_contact, ad.emergency_email, ad.emergency_mobile, ad.business_area, 
            ad.employees_total, ad.employees_with_lgu, ad.is_rented
        FROM 
            business_applications ba
        JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN application_details ad ON ba.application_id = ad.application_id
        WHERE 
            ba.application_id = %s;
    """, (application_id,))
    
    data = cursor.fetchone()
    if not data:
        return None

    if data.get('is_rented') == 'Rented':
        cursor.execute("SELECT lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent FROM lessors WHERE application_id = %s", (application_id,))
        data['lessor'] = cursor.fetchone()
    else:
        data['lessor'] = None

    cursor.execute("SELECT line_of_business, num_of_units, capitalization, gross_sales_essential, gross_sales_nonessential FROM business_activities WHERE application_id = %s", (application_id,))
    data['activities'] = cursor.fetchall()
    
    return data

def save_permit_file(application_id, pdf_bytes):
    """Saves the generated PDF to the disk and returns the server file path."""

    permit_filename = f"Permit_{application_id:04}_{uuid.uuid4().hex[:8]}.pdf"

    permit_dir = os.path.join(app.config['UPLOAD_FOLDER'],'permits')
    os.makedirs(permit_dir, exist_ok=True)

    file_path = os.path.join(permit_dir, permit_filename)

    with open(file_path, 'wb') as f:
        f.write(pdf_bytes)

    return file_path

def generate_permit_pdf(data, application_id):
    """Generates the standard Mayor's Permit PDF."""
    
    # --- Fetch Payment and Activity Data for Permit Details ---
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        cursor.execute("""
            SELECT 
                bact.line_of_business, 
                pb.or_number, pb.date_paid, pb.total_annual_due
            FROM business_applications ba
            LEFT JOIN business_activities bact ON ba.application_id = bact.application_id
            LEFT JOIN payments_billing pb ON ba.application_id = pb.application_id
            WHERE ba.application_id = %s
            LIMIT 1
        """, (application_id,))
        extra_data = cursor.fetchone() or {}
        
    finally:
        if conn and conn.open: conn.close()

    # --- Setup PDF ---
    pdf = FPDF(orientation='P', unit='mm', format='A4')
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    SEAL_PATH = 'images/buguey(logo).png'
    if os.path.exists(SEAL_PATH):
        # Image placement (adjust as necessary)
        # pdf.image(SEAL_PATH, x=15, y=10, w=30) 
        pass 

    # Header
    pdf.set_xy(10, 15)
    pdf.set_font("Arial", "B", 10)
    pdf.multi_cell(190, 5, "Republic of the Philippines\nProvince of Cagayan\nMUNICIPALITY OF BUGUEY", align="C")

    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 5, "OFFICE OF THE MAYOR", ln=1, align="C")
    pdf.set_font("Arial", "B", 16)
    pdf.cell(190, 10, "MAYOR'S PERMIT", ln=1, align="C")
    
    # Data extraction
    owner_full_name = f"{data.get('first_name', '')} {data.get('middle_name', '')} {data.get('last_name', '')}".replace("  ", " ").strip().upper()
    trade_name = data.get('trade_name', '').upper() or data.get('businessName', '').upper()
    kind_of_biz = extra_data.get('line_of_business', 'N/A').upper()
    address = data.get('business_address', '').upper()
    
    or_num = extra_data.get('or_number', 'N/A')
    date_paid_dt = extra_data.get('date_paid')
    date_paid = date_paid_dt.strftime("%B %d, %Y") if date_paid_dt else 'N/A'
    amt_paid = f"{extra_data.get('total_annual_due', 0.00):,.2f}"
    
    current_date = datetime.now()
    current_day = current_date.day
    current_month_year = current_date.strftime("%B, %Y")
    current_year = current_date.year

    # Body Fields
    pdf.ln(20)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "BUSINESS TRADE NAME:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.cell(190, 6, trade_name, ln=1, align="C")
    
    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "KIND OF BUSINESS:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.cell(190, 6, kind_of_biz, ln=1, align="C")
    
    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "OWNER/PROPRIETOR:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.cell(190, 6, owner_full_name, ln=1, align="C")
    
    pdf.ln(3)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "LOCATION OF BUSINESS:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.multi_cell(190, 6, address, 0, "C")

    # Grant Statement
    pdf.ln(10)
    pdf.set_font("Times", "", 10)
    text = "PERMIT IS HEREBY GRANTED to the above-mentioned person to engage in the above-stated business after payment of the required License/Permit Fees and compliance with the ordinances, rules and regulations governing the business trade."
    pdf.multi_cell(0, 5, text, 0, 'J', 0)
    
    pdf.ln(5)
    pdf.set_font("Times", "", 10)
    pdf.multi_cell(0, 5, f"GIVEN this {current_day} day of {current_month_year} at Buguey, Cagayan, Philippines.", 0, 'J', 0)

    # Footer / Mayor Signature
    pdf.ln(20)
    pdf.set_x(100)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(100, 5, "LICERIO MILLARE ANTIPORDA III", 0, 1, 'R')
    pdf.set_x(100)
    pdf.set_font("Arial", "", 10)
    pdf.cell(100, 5, "Municipal Mayor", 0, 1, 'R')
    
    # Details Box
    pdf.ln(10)
    pdf.set_font("Arial", "", 8)
    pdf.set_fill_color(240, 240, 240)
    pdf.cell(50, 4, f"O.R. Number: {or_num}", 0, 1, 'L', 1)
    pdf.cell(50, 4, f"Date of Issue: {date_paid}", 0, 1, 'L', 1)
    pdf.cell(50, 4, f"Amount Paid: PHP {amt_paid}", 0, 1, 'L', 1)
    pdf.cell(50, 4, f"Valid Until: December 31, {current_year}", 0, 1, 'L', 1)
    
    return pdf.output(dest='S').encode('latin1') # Return bytes

def generate_applicant_report_pdf_logic(data, application_id):
    """Generates the comprehensive application report PDF."""
    # ... (Keep this function as is in server.py)
    pdf = FPDF(orientation='P', unit='mm', format='A4')
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=10) 
    # --- Full original FPDF Report Logic (Omitted for brevity, keep your original logic here) ---
    pdf.set_font("Arial", "", 8)
    pdf.set_xy(10, 5)
    pdf.cell(50, 4, "ANNEX 1 (Page 1 of 2)", 0, 0, "L")
    # ...
    total_capitalization = sum(float(a.get('capitalization', 0.0) or 0.0) for a in data.get('activities', []))
    total_gross_essential = sum(float(a.get('gross_sales_essential', 0.0) or 0.0) for a in data.get('activities', []))
    total_gross_nonessential = sum(float(a.get('gross_sales_nonessential', 0.0) or 0.0) for a in data.get('activities', []))
    
    pdf.set_font("Arial", "B", 8)
    pdf.cell(80, 6, "TOTALS", 1, 0, "R")
    pdf.cell(35, 6, f"{total_capitalization:,.2f}", 1, 0, "R")
    pdf.cell(35, 6, f"{total_gross_essential:,.2f}", 1, 0, "R")
    pdf.cell(40, 6, f"{total_gross_nonessential:,.2f}", 1, 1, "R")

    return pdf.output(dest='B')

# Utility function kept for reference/import by admin_api, even if not used in the new VB.NET flow
# Utility function implemented for compatibility (HTML version)
def generate_permit_html_string(data, application_id):
    """
    Generates the HTML content for the Business Permit, replicating the 
    style and data fields of the original VB.NET code.
    """
    
    # 1. Fetch required payment/activity data
    conn = None
    extra_data = {}
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        cursor.execute("""
            SELECT 
                bact.line_of_business, 
                pb.or_number, pb.date_paid, pb.total_annual_due
            FROM business_applications ba
            LEFT JOIN business_activities bact ON ba.application_id = bact.application_id
            LEFT JOIN payments_billing pb ON ba.application_id = pb.application_id
            WHERE ba.application_id = %s
            LIMIT 1
        """, (application_id,))
        
        extra_data = cursor.fetchone() or {}
        
    except Exception as e:
        print(f"Error fetching extra permit data: {e}")
    finally:
        if conn and conn.open: conn.close()

    # 2. Extract and format data
    tradeName = data.get('trade_name', '').upper() or data.get('businessName', '').upper()
    kindOfBiz = extra_data.get('line_of_business', 'N/A').upper()
    owner = f"{data.get('first_name', '')} {data.get('middle_name', '')} {data.get('last_name', '')}".strip().upper()
    address = data.get('business_address', '').upper()
    
    orNum = extra_data.get('or_number', 'N/A')
    datePaid_dt = extra_data.get('date_paid')
    datePaid = datePaid_dt.strftime("%B %d, %Y") if datePaid_dt else 'N/A'
    amtPaid = f"{extra_data.get('total_annual_due', 0.00):,.2f}"

    current_date = datetime.now()
    current_day = current_date.day
    current_month_year = current_date.strftime("%B, %Y")
    current_year = current_date.year

    # 3. Build HTML string (using Python f-string mirroring VB.NET)
    html = f"""
    <html>
    <head>
        <style>
            body {{ font-family: 'Times New Roman', serif; margin: 40px; border: 5px double black; padding: 20px; height: 90%; }}
            .header {{ text-align: center; }}
            .header h2 {{ margin: 0; font-size: 18px; }}
            .header h1 {{ margin: 10px 0; font-size: 28px; text-decoration: underline; }}
            .content {{ margin-top: 30px; text-align: center; }}
            .field {{ margin-bottom: 20px; }}
            .label {{ font-size: 10px; color: gray; display: block; }}
            .value {{ font-size: 18px; font-weight: bold; border-bottom: 1px solid black; display: inline-block; width: 80%; }}
            .grant {{ margin-top: 30px; text-align: justify; text-indent: 50px; font-size: 14px; line-height: 1.5; }}
            .footer {{ margin-top: 50px; width: 100%; }}
            .mayor {{ text-align: right; margin-top: 50px; }}
            .mayor-name {{ font-weight: bold; font-size: 16px; border-top: 1px solid black; display: inline-block; padding-top: 5px; }}
            .details {{ font-size: 12px; margin-top: 30px; }}
        </style>
    </head>
    <body>
        <div class='header'>
            Republic of the Philippines<br>
            Province of Cagayan<br>
            MUNICIPALITY OF BUGUEY<br><br>
            <h2>OFFICE OF THE MAYOR</h2>
            <h1>BUSINESS PERMIT</h1>
        </div>

        <div class='content'>
            <div class='field'>
                <span class='label'>BUSINESS TRADE NAME</span>
                <span class='value'>{tradeName}</span>
            </div>
            <div class='field'>
                <span class='label'>KIND OF BUSINESS</span>
                <span class='value'>{kindOfBiz}</span>
            </div>
            <div class='field'>
                <span class='label'>OWNER / PROPRIETOR</span>
                <span class='value'>{owner}</span>
            </div>
            <div class='field'>
                <span class='label'>LOCATION OF BUSINESS</span>
                <span class='value'>{address}</span>
            </div>
        </div>

        <div class='grant'>
            PERMIT IS HEREBY GRANTED to the above-mentioned person to engage in the above-stated business after payment of the required License/Permit Fees and compliance with the ordinances, rules and regulations governing the business trade.
            <br><br>
            GIVEN this <strong>{current_day}</strong> day of <strong>{current_month_year}</strong> at Buguey, Cagayan, Philippines.
        </div>

        <div class='footer'>
            <div class='mayor'>
                <span class='mayor-name'>LICERIO MILLARE ANTIPORDA III</span><br>
                Municipal Mayor
            </div>
        </div>

        <div class='details'>
            <strong>O.R. Number:</strong> {orNum}<br>
            <strong>Date of Issue:</strong> {datePaid}<br>
            <strong>Amount Paid:</strong> PHP {amtPaid}<br>
            <strong>Valid Until:</strong> December 31, {current_year}
        </div>
    </body>
    </html>
    """
    return html

def fetch_top_data(application_id, cursor):
    """Fetches all data required for the Tax Order of Payment form."""
    
    # 1. Fetch Summary Data 
    cursor.execute("""
        SELECT
            ba.application_id, ba.application_date, ba.status,
            t.account_number AS AcctNo, t.first_name, t.last_name, 
            t.businessName AS CommercialName, t.trade_name, 
            ad.business_address,
            pb.total_tax_base, pb.total_business_tax, pb.total_regulatory_fees, 
            pb.total_other_fees, pb.surcharge_amount, pb.interest_amount, 
            pb.total_qtr_due, pb.total_annual_due,
            pb.qtr_2_amount, pb.qtr_3_amount, pb.qtr_4_amount,
            pb.sa_1_amount, pb.sa_2_amount, pb.due_date, pb.date_generated,
            pb.or_number, pb.date_paid 
        FROM business_applications ba
        JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN application_details ad ON ba.application_id = ad.application_id
        LEFT JOIN payments_billing pb ON ba.application_id = pb.application_id
        WHERE ba.application_id = %s
    """, (application_id,))
    summary = cursor.fetchone()

    if not summary:
        return None

    # 2. Fetch Fee Line Items 
    cursor.execute("""
        SELECT 
            af.fee_code AS Code, 
            af.fee_description AS TaxDescription, 
            af.tax_base AS TaxBase, 
            af.current_qtr_due AS CurrentQtrDue, 
            af.annual_due AS AnnualDue,
            af.period_covered AS PeriodCovered
        FROM application_fees af
        WHERE af.application_id = %s
        ORDER BY af.fee_code
    """, (application_id,))
    
    summary['fee_details'] = cursor.fetchall()
    
    return summary

def calculate_and_store_taxes(application_id, input_data, cursor):
    """
    Calculates taxes and stores billing records.
    """
    
    # 1. DELETE existing records
    cursor.execute("DELETE FROM application_fees WHERE application_id = %s", (application_id,))
    cursor.execute("DELETE FROM payments_billing WHERE application_id = %s", (application_id,))
    
    # 2. Determine Primary Tax Base from Admin Input
    gross_sales = float(input_data.get('gross_sales', 0.0) or 0.0)
    capitalization = float(input_data.get('capitalization', 0.0) or 0.0)
    late_months = int(input_data.get('late_months', 0) or 0)
    
    # --- CRITICAL DATE FIX: Calculate Due Date 3 days before the 20th ---
    standard_deadline = date.today().replace(month=1, day=20)
    due_date = standard_deadline - timedelta(days=3)
    # -----------------------------------------------------------------
    
    # Fetch application type using the passed DictCursor
    cursor.execute("SELECT application_type FROM business_applications WHERE application_id = %s", (application_id,))
    app_type_row = cursor.fetchone() 
    
    if app_type_row:
        app_type = app_type_row['application_type'] 
    else:
        app_type = 'New Application'
    
    primary_tax_base = capitalization if app_type == 'New Application' else gross_sales
    total_tax_base_sum = primary_tax_base 
    
    # 3. CALCULATE AND INSERT FEE LINE ITEMS (DUMMY RATES)
    cursor.execute("SELECT fee_code, description, fee_group, base_rate FROM fee_codes ORDER BY fee_group, fee_code")
    fee_codes = cursor.fetchall()
    
    total_annual_tax = 0.0; total_regulatory = 0.0; total_other = 0.0

    for fee in fee_codes:
        annual_due = 0.0
    
        tax_rate = float(fee['base_rate']) if fee['base_rate'] else 0.005

        if fee['fee_group'] == 'Tax':
            annual_due = primary_tax_base * tax_rate 
            total_annual_tax += annual_due
        elif fee['fee_group'] == 'Regulatory' or fee['fee_group'] == 'Other':
            annual_due = tax_rate 
            if fee['fee_group'] == 'Regulatory':
                total_regulatory += annual_due
            else:
                total_other += annual_due

        if annual_due > 0:
            cursor.execute("""
                INSERT INTO application_fees 
                (application_id, fee_code, fee_description, tax_base, annual_due, current_qtr_due, period_covered, fee_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (application_id, fee['fee_code'], fee['description'], primary_tax_base, annual_due, annual_due / 4, '1-4 Qtr', fee['fee_group']))
            
    # 4. CALCULATE PENALTIES AND FINAL BILLING
    surcharge_rate = 0.25; interest_rate_per_month = 0.02
    surcharge = total_annual_tax * surcharge_rate if late_months > 0 else 0.0
    interest = total_annual_tax * interest_rate_per_month * late_months
    total_qtr_due = total_annual_tax + total_regulatory + total_other + surcharge + interest
    total_annual_due = total_qtr_due
    
    # Insert final summary into payments_billing
    cursor.execute("""
        INSERT INTO payments_billing (application_id, total_tax_base, total_business_tax, total_regulatory_fees, 
                                     total_other_fees, surcharge_amount, interest_amount, total_qtr_due, 
                                     total_annual_due, qtr_2_amount, qtr_3_amount, qtr_4_amount, due_date)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (application_id, total_tax_base_sum, total_annual_tax, total_regulatory, total_other, 
          surcharge, interest, total_qtr_due, total_annual_due, total_annual_due / 4, total_annual_due / 4, total_annual_due / 4, due_date))
    
    return {'total_annual_due': total_annual_due}


def generate_top_pdf_logic(data):
    """Generates the printable Tax Order of Payment (TOP) PDF."""
    
    class PDF(FPDF):
        def header(self):
            # Municipality Information Header
            self.set_y(10)
            self.set_font('Arial', '', 8)
            self.cell(0, 3, 'Republic of the Philippines', 0, 1, 'C')
            self.cell(0, 3, 'Municipality of Buguey', 0, 1, 'C')
            self.cell(0, 3, 'Business Permit and License Office', 0, 1, 'C')
            self.ln(2)
            self.set_font('Arial', 'B', 12)
            self.cell(0, 5, 'TAX ORDER OF PAYMENT', 0, 1, 'C')
            self.set_font('Arial', '', 8)
            proc_date = data.get('date_generated', datetime.now()).strftime('%m/%d/%Y')
            self.cell(0, 5, f"Processing date : {proc_date}", 0, 1, 'R')
            self.ln(5)

        def footer(self):
            self.set_y(-10)
            self.set_font('Arial', 'I', 6)
            self.cell(0, 5, f'Page {self.page_no()}/{{nb}}', 0, 0, 'C')

    pdf = PDF('P', 'mm', 'A4')
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    # --- Data Extraction and Formatting ---
    app_id = data.get('application_id', 'N/A')
    acct_no = data.get('AcctNo', 'N/A')
    owner_name = f"{data.get('first_name', '')} {data.get('last_name', '')}".strip().upper()
    bus_name = data.get('businessName', 'N/A').upper()
    bus_address = data.get('business_address', 'N/A')
    app_type = data.get('application_type', 'N/A')
    due_date = data.get('due_date', date.today()).strftime('%B %d, %Y')
    total_annual_due = data.get('total_annual_due', 0.00)
    
    # --- 1. Header Information ---
    pdf.set_font('Arial', '', 8)
    pdf.cell(20, 5, 'App No.:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, str(app_id).zfill(4), 0, 0)
    pdf.set_font('Arial', '', 8); pdf.set_x(120); pdf.cell(20, 5, 'Ownership:', 0); pdf.cell(30, 5, data.get('business_type', 'Single'), 0, 1)
    
    pdf.set_x(10); pdf.cell(20, 5, 'Tax Payer:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(100, 5, owner_name, 0, 1)

    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Commercial Name:', 0); pdf.set_font('Arial', 'B', 8); pdf.multi_cell(100, 4, bus_name, 0, 'L') 
    
    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Business Address:', 0); pdf.set_font('Arial', 'B', 8); pdf.multi_cell(100, 4, bus_address.upper(), 0, 'L')
    
    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Status:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, app_type.upper(), 0, 0)
    
    pdf.set_font('Arial', '', 8); pdf.set_x(120); pdf.cell(20, 5, 'Still No.:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, acct_no, 0, 1)
    pdf.ln(5)

    # --- 2. Fee Details Table Header/Rows (Drawing logic simplified for brevity, use full version) ---
    pdf.set_fill_color(220, 220, 220); pdf.set_font('Arial', 'B', 7)
    col_widths = [15, 65, 25, 25, 25, 20]; headers = ['Code', 'Tax Description', 'TaxBase', 'Current Qtr Due', 'Annual Due', 'Period Cover']
    for w, h in zip(col_widths, headers): pdf.cell(w, 5, h, 1, 0, 'C', 1)
    pdf.ln()
    
    pdf.set_font('Arial', '', 7)
    fee_details = data.get('fee_details', [])
    for fee in fee_details:
        pdf.cell(15, 5, fee.get('Code', ''), 1); pdf.cell(65, 5, fee.get('TaxDescription', ''), 1)
        pdf.cell(25, 5, f"{fee.get('TaxBase', 0.00):,.2f}", 1, 0, 'R'); pdf.cell(25, 5, f"{fee.get('CurrentQtrDue', 0.00):,.2f}", 1, 0, 'R')
        pdf.cell(25, 5, f"{fee.get('AnnualDue', 0.00):,.2f}", 1, 0, 'R'); pdf.cell(20, 5, fee.get('PeriodCovered', ''), 1, 1, 'C')

    # --- 4. Summary Totals Section (Drawing logic simplified) ---
    pdf.ln(2); pdf.set_font('Arial', 'B', 8)
    w_label = 30; w_amount = 30; total_annual_due = data.get('total_annual_due', 0.00)
    pdf.cell(w_label, 5, 'Business Tax (A)', 1, 0, 'C'); pdf.cell(w_amount, 5, 'Regulatory Fees (A)', 1, 0, 'C')
    pdf.cell(w_amount, 5, 'Other Fees', 1, 0, 'C'); pdf.cell(w_label - 10, 5, 'Surcharge', 1, 0, 'C')
    pdf.cell(w_label - 10, 5, 'Interest', 1, 0, 'C'); pdf.set_font('Arial', 'B', 8); pdf.cell(w_label + 10, 5, 'Total Annual Due', 1, 1, 'C') 
    
    pdf.set_font('Arial', '', 8)
    pdf.cell(w_label, 5, f"{data.get('total_business_tax', 0.00):,.2f}", 1, 0, 'R') # ... (and so on for all summary rows)

    # --- 5. Installment Breakdown (Drawing logic simplified) ---
    pdf.ln(5); pdf.set_font('Arial', 'B', 8)
    w_qtr = 25; w_sa = 35
    pdf.cell(w_qtr * 3, 5, 'QUARTERLY DUES', 1, 0, 'C'); pdf.cell(w_sa * 2, 5, 'SEMI-ANNUAL', 1, 1, 'C')
    # ... (Drawing cells for Qtr/SA amounts) ...
    
    # --- Signature and Note Section (Drawing logic simplified) ---
    pdf.ln(10); pdf.set_font('Arial', 'B', 8)
    pdf.cell(0, 5, f"Balance to be paid / Renewal On or Before : {due_date}", 0, 1, 'C')
    
    pdf.ln(10); pdf.set_font('Arial', 'B', 8)
    or_info = f"Last Payment ORNO: {data.get('or_number', '_______')} [DATE: {data.get('date_paid', '_______')}] [AMOUNT: {total_annual_due:,.2f}]"
    pdf.multi_cell(0, 4, or_info, 0, 'L')
    
    return pdf.output(dest='S').encode('latin1')

   
# Mayor's Permit PDF Generation Logic
# def generate_permit_pdf(data, application_id):
#     """Generates the standard Mayor's Permit PDF."""
#     permit_number_display = f"No. {application_id:04}" 
    
#     pdf = FPDF(orientation='P', unit='mm', format='A4')
#     pdf.add_page()
#     pdf.set_auto_page_break(auto=True, margin=15)

#     SEAL_PATH = 'images/buguey(logo).png'
#     if os.path.exists(SEAL_PATH):
#         pdf.image(SEAL_PATH, x=15, y=10, w=30) 

#     pdf.set_xy(10, 15)
#     pdf.set_font("Arial", "B", 10)
#     pdf.multi_cell(190, 5, "Republic of the Philippines\nProvince of Cagayan\nMUNICIPALITY OF BUGUEY", align="C")

#     pdf.ln(5)
#     pdf.set_font("Arial", "B", 12)
#     pdf.cell(190, 5, "OFFICE OF THE MAYOR", ln=1, align="C")
#     pdf.set_font("Arial", "B", 16)
#     pdf.cell(190, 10, "MAYOR'S PERMIT", ln=1, align="C")
    
#     owner_full_name = f"{data.get('first_name', '')} {data.get('middle_name', '')} {data.get('last_name', '')}".replace("  ", " ").strip().upper()
    
#     pdf.ln(20)
#     pdf.set_font("Arial", "B", 12)
#     pdf.cell(190, 8, "BUSINESS TRADE NAME:", ln=1, align="L")
#     pdf.set_font("Arial", "", 12)
#     pdf.cell(190, 6, data['trade_name'].upper(), ln=1, align="C")
    
#     pdf.ln(3)
#     pdf.set_font("Arial", "B", 12)
#     pdf.cell(190, 8, "OWNER/PROPRIETOR:", ln=1, align="L")
#     pdf.set_font("Arial", "", 12)
#     pdf.cell(190, 6, owner_full_name, ln=1, align="C")

#     # This is where the rest of the original FPDF logic for the permit goes...
    
#     return pdf.output(dest='B') 

# # Application Report PDF Generation Logic (The massive FPDF block for the form)
# def generate_applicant_report_pdf_logic(data, application_id):
#     """Generates the comprehensive application report PDF."""
    
#     pdf = FPDF(orientation='P', unit='mm', format='A4')
#     pdf.add_page()
#     pdf.set_auto_page_break(auto=True, margin=10) 
    
#     # --- Full original FPDF Report Logic (Copied from your original code) ---
#     pdf.set_font("Arial", "", 8)
#     pdf.set_xy(10, 5)
#     pdf.cell(50, 4, "ANNEX 1 (Page 1 of 2)", 0, 0, "L")
    
#     # ... (All the detailed FPDF drawing/cell logic from your original report function) ...

#     # Totals Calculation
#     total_capitalization = sum(float(a.get('capitalization', 0.0) or 0.0) for a in data.get('activities', []))
#     total_gross_essential = sum(float(a.get('gross_sales_essential', 0.0) or 0.0) for a in data.get('activities', []))
#     total_gross_nonessential = sum(float(a.get('gross_sales_nonessential', 0.0) or 0.0) for a in data.get('activities', []))
    
#     pdf.set_font("Arial", "B", 8)
#     pdf.cell(80, 6, "TOTALS", 1, 0, "R")
#     pdf.cell(35, 6, f"{total_capitalization:,.2f}", 1, 0, "R")
#     pdf.cell(35, 6, f"{total_gross_essential:,.2f}", 1, 0, "R")
#     pdf.cell(40, 6, f"{total_gross_nonessential:,.2f}", 1, 1, "R")

#     return pdf.output(dest='B') 

# --- MOBILE APP ROUTES (All Endpoints Here) ---

@app.route("/")
def home():
    return {"message": "Flask backend is running! Admin endpoints loaded via Blueprint."}

# ✅ PAYMENT ENDPOINT
@app.route("/create_payment", methods=["POST"])
def create_payment():
    data = request.get_json()
    print(f"📩 Received payment data: {data}")

    required_fields = ["user_id", "application_id", "amount", "first_name", "last_name", "email"]
    if not all(field in data and data[field] for field in required_fields):
        return jsonify({"success": False, "message": "Missing required fields."}), 400

    try:
        user_id = data["user_id"]
        application_id = int(data["application_id"])
        amount = float(data["amount"])
        email = data["email"]

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO payments (user_id, application_id, amount, status)
            VALUES (%s, %s, %s, 'PENDING')
        """, (user_id, application_id, amount))
        conn.commit()

        invoice_data = {
            "external_id": f"APP-{application_id}-{int(datetime.now().timestamp())}",
            "amount": amount,
            "payer_email": email,
            "description": "Business Permit Application Fee",
            "success_redirect_url": f"http://192.168.1.100:5000/payment_success?application_id={application_id}",
            "failure_redirect_url": f"http://192.168.1.100:5000/payment_failed?application_id={application_id}"
        }

        response = requests.post(
            XENDIT_INVOICE_URL,
            auth=(XENDIT_SECRET_KEY, ""),
            json=invoice_data
        )

        xendit_response = response.json()
        invoice_url = xendit_response.get("invoice_url")
        invoice_id = xendit_response.get("id")

        if not invoice_url:
            return jsonify({"success": False, "message": "Failed to create Xendit invoice", "response": xendit_response}), 400

        cursor.execute("""
            UPDATE payments 
            SET checkout_url = %s, maya_transaction_id = %s
            WHERE application_id = %s
        """, (invoice_url, invoice_id, application_id))
        conn.commit()
        conn.close()

        return jsonify({"success": True, "checkout_url": invoice_url})

    except Exception as e:
        print(f"❌ Error in create_payment: {traceback.format_exc()}")
        return jsonify({"success": False, "message": f"Server error: {str(e)}"}), 500

# ✅ TESTING/PENDING APPLICATION (Mobile)
@app.route("/get_pending_application", methods=["GET"])
def get_pending_application():
    user_id = request.args.get("user_id")
    if not user_id: 
        return jsonify({"success": False, "message": "Missing user_id parameter"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) # DictCursor used for reliable key access
        
        # Selects the most recent application that is NOT explicitly Draft, Rejected, or Completed.
        cursor.execute("""
            SELECT application_id, status 
            FROM business_applications 
            WHERE user_id = %s 
              AND status NOT IN ('Draft', 'Rejected', 'Completed') 
            ORDER BY application_date DESC 
            LIMIT 1
        """, (user_id,))
        
        result = cursor.fetchone()
        
        if result:
            return jsonify({
                "success": True, 
                "application_id": str(result['application_id']), 
                "message": "Active application ID retrieved successfully."
            }), 200
        else:
            return jsonify({"success": False, "message": "No active application found for this user."}), 404
            
    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "message": f"Server Error: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.route('/renewal', methods=['POST'])
def renewal():
    try:
        user_id = request.form.get('user_id')
        taxpayer_id = request.form.get('taxpayer_id')
        tin_no = request.form.get('tin_no')
        mode_of_payment = request.form.get('mode_of_payment')
        business_type = request.form.get('business_type')

        conn = get_db_connection()
        with conn.cursor() as cursor:
            sql = """INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date, tin_no, mode_of_payment, business_type, status)
                     VALUES (%s, %s, 'Renewal', CURDATE(), %s, %s, %s, 'Pending Review')"""
            cursor.execute(sql, (user_id, taxpayer_id, tin_no, mode_of_payment, business_type))
            conn.commit()
            new_application_id = cursor.lastrowid

        uploaded_files = request.files.getlist('documents')
        for file in uploaded_files:
            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(file_path)

                with conn.cursor() as cursor:
                    cursor.execute("""INSERT INTO uploaded_documents (application_id, document_name, file_path) VALUES (%s, %s, %s)""", (new_application_id, filename, file_path))
                    conn.commit()

        conn.close()

        return jsonify({"message": "Renewal submitted successfully", "application_id": new_application_id}), 200

    except Exception as e:
        print("Error:", str(e))
        return jsonify({"error": str(e)}), 500

# ✅ GET APPROVED BUSINESSES (Mobile Renewal Helper)
@app.route("/api/approved_businesses", methods=["GET"])
def get_approved_businesses():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        cursor.execute("""SELECT ba.application_id, t.businessName AS business_name, ad.business_address, ad.owner_mobile AS contact_number, ad.owner_email AS email, ba.status, ba.application_date AS date_applied, t.taxpayer_id, CONCAT(t.first_name, ' ', t.last_name) AS owner_name, bact.line_of_business, bact.num_of_units, bact.capitalization, bact.gross_sales_essential, bact.gross_sales_nonessential FROM business_applications ba JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id JOIN application_details ad ON ba.application_id = ad.application_id LEFT JOIN business_activities bact ON ba.application_id = bact.application_id WHERE ba.status = 'Approved' AND ba.application_type != 'Retirement'""")
        businesses = cursor.fetchall()
        conn.close()
        return jsonify({"businesses": businesses}), 200
    except Exception as e:
        print("Error fetching approved businesses:", str(e))
        return jsonify({"error": "Failed to load businesses: " + str(e)}), 500

# ✅ SUBMIT RENEWAL V2 (Mobile)
@app.route("/api/submit_renewal", methods=["POST"])
def submit_renewal_v2():
    try:
        data = request.get_json()
        original_application_id = data.get("business_id") 
        line_of_business = data.get('line_of_business')
        num_of_units = data.get('num_of_units')
        capitalization = data.get('capitalization')
        gross_sales_essential = data.get('gross_sales_essential')
        gross_sales_nonessential = data.get('gross_sales_nonessential')

        if not original_application_id: return jsonify({"success": False, "message": "Original business ID is required for renewal."}), 400

        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT user_id, taxpayer_id, tin_no, mode_of_payment, business_type FROM business_applications WHERE application_id = %s", (original_application_id,))
        original_data = cursor.fetchone()

        if not original_data: conn.close(); return jsonify({"success": False, "message": "Original approved business not found."}), 404

        sql_app = """INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date, tin_no, mode_of_payment, business_type, status)
                     VALUES (%s, %s, 'Renewal', CURDATE(), %s, %s, %s, 'Pending Review')"""
        cursor.execute(sql_app, (original_data['user_id'], original_data['taxpayer_id'], original_data['tin_no'], original_data['mode_of_payment'], original_data['business_type']))
        conn.commit()
        new_renewal_id = cursor.lastrowid

        if line_of_business:
            sql_bact = """INSERT INTO business_activities (application_id, line_of_business, num_of_units, capitalization, gross_sales_essential, gross_sales_nonessential)
                          VALUES (%s, %s, %s, %s, %s, %s)"""
            cursor.execute(sql_bact, (new_renewal_id, line_of_business, num_of_units if num_of_units is not None else 0, capitalization if capitalization is not None else 0.0, gross_sales_essential if gross_sales_essential is not None else 0.0, gross_sales_nonessential if gross_sales_nonessential is not None else 0.0))
            conn.commit()

        conn.close()
        return jsonify({"success": True, "message": "Renewal application created successfully with activities.", "renewal_id": new_renewal_id}), 200
        
    except Exception as e:
        print("Error submitting renewal:", str(e))
        return jsonify({"success": False, "message": "Server error during renewal submission: " + str(e)}), 500

# ✅ SIGN UP
@app.route("/signup", methods=["POST"])
def signup():
    data = request.json
    required = ["first_name", "last_name", "email", "password", "mobile_number"]
    missing = [f for f in required if not data.get(f)]
    if missing: return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    password_hash = generate_password_hash(data["password"])
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""INSERT INTO users (first_name, last_name, middle_name, email, password_hash, mobile_number) VALUES (%s, %s, %s, %s, %s, %s)""", (data["first_name"], data["last_name"], data.get("middle_name", ""), data["email"], password_hash, data["mobile_number"]))
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
    if not email or not password: return jsonify({"status": "error", "message": "Email and password are required"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT user_id, email, first_name, last_name, password_hash FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if not user: return jsonify({"status": "error", "message": "Invalid credentials"}), 401

        user_id, email, first_name, last_name, password_hash = user
        if check_password_hash(password_hash, password):
            return jsonify({"status": "success", "message": "Login successful", "user": {"user_id": user_id, "email": email, "first_name": first_name, "last_name": last_name}}), 200
        else:
            return jsonify({"status": "error", "message": "Invalid credentials"}), 401
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# ✅ FORGOT PASSWORD
@app.route("/forgot_password", methods=["POST"])
def forgot_password():
    data = request.json
    email = data.get("email")
    if not email: return jsonify({"status": "error", "message": "Email is required to reset password"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT user_id FROM users WHERE email=%s", (email,))
        user_data = cursor.fetchone()
        
        if user_data:
            return jsonify({"status": "success", "message": "Email verified. Proceed to reset password.", "user_id": user_data["user_id"]}), 200
        else:
            return jsonify({"status": "error", "message": "Email address not found."}), 404

    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"An unexpected server error occurred: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# ✅ RESET PASSWORD
@app.route("/reset_password", methods=["POST"])
def reset_password():
    data = request.json
    email = data.get("email")
    new_password = data.get("new_password")

    if not email or not new_password: return jsonify({"status": "error", "message": "Email and new password are required"}), 400

    conn = None
    cursor = None
    try:
        new_password_hash = generate_password_hash(new_password)
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""UPDATE users SET password_hash = %s WHERE email = %s""", (new_password_hash, email))
        conn.commit()
        
        if cursor.rowcount == 0: return jsonify({"status": "error", "message": "User not found or password was not changed."}), 404

        return jsonify({"status": "success", "message": "Your password has been successfully updated. You can now sign in."}), 200

    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"An unexpected server error occurred: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

# server.py (Inside def submit_application(): )

@app.route("/submit_application", methods=["POST"])
def submit_application():
    data = request.get_json()
    user_id = data.get("user_id")

    # --- 1. VALIDATION FIX (CRITICAL for NOT NULL fields) ---
    required_taxpayer_fields = ["first_name", "last_name"]
    for field in required_taxpayer_fields:
        # If the mobile app sends null or an empty string, fail early (HTTP 400).
        if not data.get(field) or data.get(field).strip() == "":
            return jsonify({"status": "error", "message": f"Submission failed: Missing required Taxpayer field: {field.replace('_', ' ')}"}), 400
    # -------------------------------------------------------------
    
    if not user_id: return jsonify({"status": "error", "message": "Missing user_id. Please log in again."}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Prepare Taxpayer Data: Use .strip() or None for optional fields
        taxpayer_data_tuple = (
            data.get("first_name", "").strip(), 
            data.get("last_name", "").strip(),
            data.get("middle_name", "").strip() or None,  # Optional fields sent as None/NULL
            data.get("trade_name", "").strip() or None,
            data.get("businessName", "").strip() or None,
            data.get("account_number", "").strip() or None,
            data.get("has_tax_incentive", 0),
            data.get("tax_incentive_entity", "").strip() or None
        )

        # 2. Insert Taxpayer
        cursor.execute("""INSERT INTO taxpayers (first_name, last_name, middle_name, trade_name, businessName, account_number, has_tax_incentive, tax_incentive_entity)
                         VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""", taxpayer_data_tuple)
        
        taxpayer_id = cursor.lastrowid
        if not taxpayer_id: 
            # This guard now confirms a DB constraint (other than NOT NULL on name) or internal error occurred.
            raise Exception("Failed to retrieve auto-generated Taxpayer ID.") 

        # 3. Insert Business Application
        cursor.execute("""INSERT INTO business_applications (user_id, taxpayer_id, application_type, application_date, tin_no, mode_of_payment, business_type, amendment_from, amendment_to, status)
                         VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'Pending Documents')""", (user_id, taxpayer_id, data.get("application_type", ""), data.get("application_date", str(date.today())), data.get("tin_no", ""), data.get("mode_of_payment", ""), data.get("business_type", ""), data.get("amendment_from", ""), data.get("amendment_to", "")))
        application_id = cursor.lastrowid
        if not application_id: raise Exception("Failed to get last inserted Application ID.")
        
        # 4. Prepare common fields
        is_rented_val = data.get("is_rented", 0)
        is_rented_db_value = 'Rented' if is_rented_val == 1 else 'Owned'
        business_area_val = float(data.get("business_area", 0.0) or 0.0)

        # 5. Insert Application Details
        cursor.execute("""INSERT INTO application_details (application_id, business_address, postal_code, owner_address, owner_email, owner_mobile, emergency_contact, emergency_email, emergency_mobile, business_area, employees_total, employees_with_lgu, is_rented)
                         VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""", (application_id, data.get("business_address", ""), data.get("postal_code", ""), data.get("owner_address", ""), data.get("owner_email", ""), data.get("owner_mobile", ""), data.get("emergency_contact", ""), data.get("emergency_email", ""), data.get("emergency_mobile", ""), business_area_val, data.get("employees_total", 0), data.get("employees_with_lgu", 0), is_rented_db_value))

        # 6. Insert Lessor Info (Robust against empty strings for NOT NULL fields)
        if is_rented_val == 1:
            lessor_name = data.get("lessor_name", "").strip() or "N/A"
            lessor_address = data.get("lessor_address", "").strip() or "N/A"
            lessor_email = data.get("lessor_email", "").strip() or None # Use None for optional email/mobile
            lessor_mobile = data.get("lessor_mobile", "").strip() or None
            
            monthly_rent_val = float(data.get("monthly_rent", 0.0) or 0.0)
            
            cursor.execute("""INSERT INTO lessors (application_id, lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent)
                             VALUES (%s, %s, %s, %s, %s, %s)""", (
                                 application_id, 
                                 lessor_name, 
                                 lessor_address, 
                                 lessor_email, 
                                 lessor_mobile, 
                                 monthly_rent_val
                             ))

        # 7. Insert Business Activities
        cursor.execute("""INSERT INTO business_activities (application_id, line_of_business, num_of_units, capitalization, gross_sales_essential, gross_sales_nonessential)
                         VALUES (%s, %s, %s, %s, %s, %s)""", (application_id, data.get("line_of_business", ""), int(data.get("num_of_units", 0) or 0), float(data.get("capitalization", 0.0) or 0.0), float(data.get("gross_sales_essential", 0.0) or 0.0), float(data.get("gross_sales_non_essential", 0.0) or 0.0)))

        conn.commit()
        
        return jsonify({"status": "success", "message": "Application submitted successfully! Proceed to upload documents.", "application_id": application_id}), 201 

    except Exception as e:
        if conn: conn.rollback()
        import traceback
        print(f"❌ Database error during submission. Rolling back transaction.")
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Submission failed due to a server error. Check server logs."}), 500

    finally:
        if conn: conn.close()
# ✅ DOCUMENT UPLOAD
# server.py (Add this route)

@app.route("/get_user_profile/<string:user_id>", methods=["GET"])
def get_user_profile(user_id):
    if not user_id:
        return jsonify({"status": "error", "message": "Missing user ID."}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) # Use dictionary=True for column names
        
        # Query the users table for name fields
        cursor.execute(
            """SELECT first_name, middle_name, last_name, email, mobile_number 
               FROM users WHERE user_id = %s""", 
            (user_id,)
        )
        user_data = cursor.fetchone()
        
        if user_data:
            return jsonify({
                "status": "success",
                "user_data": user_data
            }), 200
        else:
            return jsonify({"status": "error", "message": "User not found."}), 404

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Server error fetching user profile."}), 500
    
    finally:
        if conn: conn.close()

@app.route("/get_requirements/<string:app_type>", methods=["GET"])
def get_requirements_by_type(app_type):
    """Fetches document requirements for a specific application type."""
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        
        # Selects documents required for the specific type OR for 'Both'
        cursor.execute("""
            SELECT req_code, description 
            FROM document_requirements 
            WHERE application_type = %s OR application_type = 'Both'
            ORDER BY req_code;
        """, (app_type,))
        
        requirements = cursor.fetchall()
        return jsonify({"status": "success", "requirements": requirements}), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to fetch requirements."}), 500
    finally:
        if conn: conn.close()

        # In server.py / @app.route('/upload_document', methods=['POST'])

@app.route('/upload_document', methods=['POST'])
def upload_document():
    # Retrieve all necessary data fields from the POST request form
    application_id = request.form.get('application_id')
    document_code = request.form.get('document_name')  # Using 'document_name' as the code
    document_purpose = request.form.get('document_purpose')
    
    # --- Start Try Block ---
    try:
        # 1. Validation Check (Mandatory fields for DB insert)
        if not all([application_id, document_code, document_purpose]):
            return jsonify({"status": "error", "message": "Missing application ID, document code, or document purpose."}), 400

        # 2. File Check
        if 'document' not in request.files:
            return jsonify({"status": "error", "message": "No file part in the request."}), 400
        
        file = request.files['document']
        if file.filename == '': 
            return jsonify({"status": "error", "message": "No selected file."}), 400

        # 3. Save File Safely
        if file and allowed_file(file.filename):
            
            # --- FIX: Generate unique filename using UUID ---
            original_filename = secure_filename(file.filename)
            file_extension = original_filename.rsplit('.', 1)[-1] if '.' in original_filename else 'dat'
            
            unique_disk_name = f"{uuid.uuid4().hex}.{file_extension}"
            
            upload_dir = app.config['UPLOAD_FOLDER']
            os.makedirs(upload_dir, exist_ok=True)
            file_path_on_server = os.path.join(upload_dir, unique_disk_name)
            
            file.save(file_path_on_server)

            # 4. Record Metadata in DB
            conn = get_db_connection()
            with conn.cursor() as cursor:
                sql = """INSERT INTO uploaded_documents (application_id, req_code, document_purpose, file_path)
                             VALUES (%s, %s, %s, %s)"""
                cursor.execute(sql, (
                   application_id, 
                   document_code,  # document_code variable still holds the req_code value
                   document_purpose, 
                   file_path_on_server
               ))
            conn.commit()
            conn.close()

            return jsonify({"status": "success", "message": f"{document_code} uploaded successfully"}), 200

        else:
            return jsonify({"status": "error", "message": "File type not allowed. Must be PDF, PNG, or JPG."}), 400

    except Exception as e:
        # Note: Added traceback printing for debugging (should be removed in production)
        print(f"Server Error during document upload: {traceback.format_exc()}")
        return jsonify({"status": "error", "message": f"Server error processing upload. Try again."}), 500

# @app.route('/upload_document', methods=['POST'])
# def upload_document():
#     try:
#         application_id = request.form.get('application_id')
#         document_code = request.form.get('document_name') 
#         document_purpose = request.form.get('document_purpose')

#         if not application_id or not document_code or not document_purpose: return jsonify({"status": "error", "message": "Missing application ID, document code, or document purpose."}), 400

#         if 'document' not in request.files: return jsonify({"status": "error", "message": "No file part in the request (Expected field name: 'document')."}), 400
#         file = request.files['document']
#         if file.filename == '': return jsonify({"status": "error", "message": "No selected file."}), 400

#         if file and allowed_file(file.filename):
#             original_filename = secure_filename(file.filename)
#             filename = f"{application_id}_{document_code}_{document_purpose}_{original_filename}"
            
#             upload_dir = app.config['UPLOAD_FOLDER']
#             os.makedirs(upload_dir, exist_ok=True)
#             file_path_on_server = os.path.join(upload_dir, filename)
            
#             file.save(file_path_on_server)

#             conn = get_db_connection()
#             with conn.cursor() as cursor:
#                 sql = """INSERT INTO uploaded_documents (application_id, document_name, document_purpose, file_path)
#                          VALUES (%s, %s, %s, %s)"""
#                 cursor.execute(sql, (application_id, document_code, document_purpose, file_path_on_server))
#                 conn.commit()
#             conn.close()

#             return jsonify({"status": "success", "message": f"{document_code} uploaded successfully"}), 200

#         else:
#             return jsonify({"status": "error", "message": "File type not allowed. Must be PDF, PNG, or JPG."}), 400

#     except Exception as e:
#         print(f"Server Error during document upload: {str(e)}")
#         return jsonify({"status": "error", "message": f"Server error processing upload. Try again."}), 500

# # ✅ GET LAST APPLICATION DETAILS (Renewal Helper)
# @app.route("/user/get_last_application_details/<string:user_id>", methods=["GET"])
# def get_last_application_details(user_id):
#     conn = None
#     cursor = None
#     try:
#         conn = get_db_connection()
#         cursor = conn.cursor(pymysql.cursors.DictCursor)
#         cursor.execute("""SELECT application_id FROM business_applications ba WHERE ba.user_id = %s ORDER BY ba.application_date DESC LIMIT 1""", (user_id,))
#         result = cursor.fetchone()
        
#         if not result: return jsonify({"status": "error", "message": "No previous application found for renewal."}), 404
            
#         application_id = result['application_id']
#         full_data = fetch_full_application_details(application_id, cursor)
        
#         if full_data:
#             if full_data['activities']: full_data.update(full_data['activities'][0])
#             full_data.pop('activities', None) 
#             return jsonify({"status": "success", "data": full_data}), 200
        
#         return jsonify({"status": "error", "message": "Application details incomplete."}), 404
            
#     except Exception as e:
#         traceback.print_exc()
#         return jsonify({"status": "error", "message": f"Server error fetching renewal data: {str(e)}"}), 500
#     finally:
#         if cursor: cursor.close()
#         if conn: conn.close()

# ✅ GET USER APPLICATIONS (Dashboard)
@app.route("/user/applications/<string:user_id>", methods=["GET"])
def get_user_applications(user_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""SELECT ba.application_id, ba.application_type, ba.application_date, ba.status, ba.permit_issue_date, ba.permit_expiry_date, t.trade_name, t.businessName, t.first_name, t.last_name, ad.business_address FROM business_applications ba JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id LEFT JOIN application_details ad ON ba.application_id = ad.application_id WHERE ba.user_id = %s ORDER BY ba.application_date DESC""", (user_id,))
        applications = cursor.fetchall()
        conn.close()
        
        for app in applications:
            for key, value in app.items():
                if isinstance(value, (date, datetime)): app[key] = value.isoformat()
        
        return jsonify({"status": "success", "data": applications}), 200
        
    except Exception as e:
        print(f"Error fetching user applications: {traceback.format_exc()}")
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500

# ✅ GET MY APPLICATIONS (Dashboard)
@app.route("/user/get_my_applications/<int:user_id>", methods=["GET"])
def get_my_applications(user_id):
    conn = None 
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        cursor.execute("""SELECT ba.application_id, ba.status, DATE_FORMAT(ba.application_date, '%%Y-%%m-%%d') AS application_date, t.businessName, t.trade_name, ad.business_address, DATE_FORMAT(ba.permit_issue_date, '%%Y-%%m-%%d') AS permit_issue_date, DATE_FORMAT(ba.permit_expiry_date, '%%Y-%%m-%%d') AS permit_expiry_date FROM business_applications ba JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id JOIN application_details ad ON ba.application_id = ad.application_id WHERE ba.user_id = %s ORDER BY ba.application_date DESC;""", (user_id,))
        applications = cursor.fetchall()

        return jsonify(applications), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": "Failed to retrieve user applications."}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()


@app.route("/user/download_permit/<int:application_id>", methods=["GET"])
def download_permit_user(application_id):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        data = fetch_application_data(application_id, cursor)
        if not data: return jsonify({"error": "Application not found."}), 404
        if data.get('status') != 'Approved': return jsonify({"error": f"Application ID {application_id} is not Approved. Current status: {data.get('status')}"}), 403
        pdf_bytes = generate_permit_pdf(data, application_id) 
        return send_file(io.BytesIO(pdf_bytes), mimetype='application/pdf', as_attachment=True, download_name=f'Mayor_Permit_{application_id:04}.pdf')
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": f"Server error during certificate generation: {str(e)}"}), 500
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

def fetch_user_application_and_payment_status(user_id, cursor):
    """
    Fetches the most recent application status and payment details, 
    including the business name.
    """
    cursor.execute("""
        SELECT
            ba.application_id,
            ba.status,
            t.businessName, 
            pb.due_date,
            pb.date_paid,
            pb.total_annual_due
        FROM
            business_applications ba
        JOIN
            taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        LEFT JOIN
            payments_billing pb ON ba.application_id = pb.application_id
        WHERE
            ba.user_id = %s
            AND ba.status NOT IN ('Draft', 'Rejected', 'Completed') 
        ORDER BY
            ba.application_date DESC
        LIMIT 1;
    """, (user_id,))
    
    data = cursor.fetchone() 
    
    if data:
        # Convert date objects to string for JSON output safety and Flutter consumption
        if isinstance(data.get('due_date'), date):
            data['due_date'] = data['due_date'].strftime('%B %d, %Y')
        if isinstance(data.get('date_paid'), date):
            data['date_paid'] = data['date_paid'].strftime('%B %d, %Y')

    return data

def fetch_top_data(application_id, cursor):
    """Fetches all data required for the Tax Order of Payment form."""
    
    # 1. Fetch Summary Data 
    cursor.execute("""
        SELECT
            ba.application_id, ba.application_date, ba.status,
            t.account_number AS AcctNo, t.first_name, t.last_name, 
            t.businessName AS CommercialName, t.trade_name, 
            ad.business_address,
            pb.total_tax_base, pb.total_business_tax, pb.total_regulatory_fees, 
            pb.total_other_fees, pb.surcharge_amount, pb.interest_amount, 
            pb.total_qtr_due, pb.total_annual_due,
            pb.qtr_2_amount, pb.qtr_3_amount, pb.qtr_4_amount,
            pb.sa_1_amount, pb.sa_2_amount, pb.due_date, pb.date_generated,
            pb.or_number, pb.date_paid 
        FROM business_applications ba
        JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN application_details ad ON ba.application_id = ad.application_id
        LEFT JOIN payments_billing pb ON ba.application_id = pb.application_id
        WHERE ba.application_id = %s
    """, (application_id,))
    summary = cursor.fetchone()

    if not summary:
        return None

    # 2. Fetch Fee Line Items 
    cursor.execute("""
        SELECT 
            af.fee_code AS Code, 
            af.fee_description AS TaxDescription, 
            af.tax_base AS TaxBase, 
            af.current_qtr_due AS CurrentQtrDue, 
            af.annual_due AS AnnualDue,
            af.period_covered AS PeriodCovered
        FROM application_fees af
        WHERE af.application_id = %s
        ORDER BY af.fee_code
    """, (application_id,))
    
    summary['fee_details'] = cursor.fetchall()
    
    return summary

def calculate_and_store_taxes(application_id, input_data, cursor):
    """
    CRITICAL FIX: Correctly accesses app_type using the dictionary key 
    from the DictCursor result.
    """
    
    # 1. DELETE existing records
    cursor.execute("DELETE FROM application_fees WHERE application_id = %s", (application_id,))
    cursor.execute("DELETE FROM payments_billing WHERE application_id = %s", (application_id,))
    
    # 2. Determine Primary Tax Base from Admin Input
    gross_sales = float(input_data.get('gross_sales', 0.0) or 0.0)
    capitalization = float(input_data.get('capitalization', 0.0) or 0.0)
    late_months = int(input_data.get('late_months', 0) or 0)
    
    # --- CRITICAL DATE FIX: Calculate Due Date 3 days before the 20th ---
    standard_deadline = date.today().replace(month=1, day=20)
    due_date = standard_deadline - timedelta(days=3)
    # -----------------------------------------------------------------
    
    # Fetch application type using the passed DictCursor
    cursor.execute("SELECT application_type FROM business_applications WHERE application_id = %s", (application_id,))
    app_type_row = cursor.fetchone() 
    
    if app_type_row:
        # FIX: Access the dictionary value using the column name key
        app_type = app_type_row['application_type'] 
    else:
        app_type = 'New Application'
    
    primary_tax_base = capitalization if app_type == 'New Application' else gross_sales
    total_tax_base_sum = primary_tax_base 
    
    # 3. CALCULATE AND INSERT FEE LINE ITEMS (DUMMY RATES)
    # ... (rest of calculation logic remains the same) ...
    cursor.execute("SELECT fee_code, description, fee_group, base_rate FROM fee_codes ORDER BY fee_group, fee_code")
    fee_codes = cursor.fetchall()
    
    total_annual_tax = 0.0; total_regulatory = 0.0; total_other = 0.0

         
    for fee in fee_codes:
        annual_due = 0.0
    
    # CRITICAL FIX: Convert base_rate (Decimal object) to float 
        tax_rate = float(fee['base_rate']) if fee['base_rate'] else 0.005

    # --- PLACEHOLDER TAX CALCULATION LOGIC ---
        if fee['fee_group'] == 'Tax':
        # This is where the error occurred: FIXES primary_tax_base * tax_rate
            annual_due = primary_tax_base * tax_rate 
            total_annual_tax += annual_due
        elif fee['fee_group'] == 'Regulatory' or fee['fee_group'] == 'Other':
        # This handles fixed fees which are already floats due to the cast above
            annual_due = tax_rate 
            if fee['fee_group'] == 'Regulatory':
            # FIX: Ensure total_annual_tax is float as well
                total_regulatory += annual_due
            else:
                total_other += annual_due

        if annual_due > 0:
            cursor.execute("""
                INSERT INTO application_fees 
                (application_id, fee_code, fee_description, tax_base, annual_due, current_qtr_due, period_covered, fee_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (application_id, fee['fee_code'], fee['description'], primary_tax_base, annual_due, annual_due / 4, '1-4 Qtr', fee['fee_group']))
            
    # 4. CALCULATE PENALTIES AND FINAL BILLING
    surcharge_rate = 0.25; interest_rate_per_month = 0.02
    surcharge = total_annual_tax * surcharge_rate if late_months > 0 else 0.0
    interest = total_annual_tax * interest_rate_per_month * late_months
    total_qtr_due = total_annual_tax + total_regulatory + total_other + surcharge + interest
    total_annual_due = total_qtr_due
    
    # Insert final summary into payments_billing
    cursor.execute("""
        INSERT INTO payments_billing (application_id, total_tax_base, total_business_tax, total_regulatory_fees, 
                                      total_other_fees, surcharge_amount, interest_amount, total_qtr_due, 
                                      total_annual_due, qtr_2_amount, qtr_3_amount, qtr_4_amount, due_date)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (application_id, total_tax_base_sum, total_annual_tax, total_regulatory, total_other, 
          surcharge, interest, total_qtr_due, total_annual_due, total_annual_due / 4, total_annual_due / 4, total_annual_due / 4, due_date))
    
    return {'total_annual_due': total_annual_due}

def generate_top_pdf_logic(data):
    """Generates the printable Tax Order of Payment (TOP) PDF."""
    
    class PDF(FPDF):
        def header(self):
            # Municipality Information Header
            self.set_y(10)
            self.set_font('Arial', '', 8)
            self.cell(0, 3, 'Republic of the Philippines', 0, 1, 'C')
            self.cell(0, 3, 'Municipality of Buguey', 0, 1, 'C')
            self.cell(0, 3, 'Business Permit and License Office', 0, 1, 'C')
            self.ln(2)
            self.set_font('Arial', 'B', 12)
            self.cell(0, 5, 'TAX ORDER OF PAYMENT', 0, 1, 'C')
            self.set_font('Arial', '', 8)
            proc_date = data.get('date_generated', datetime.now()).strftime('%m/%d/%Y')
            self.cell(0, 5, f"Processing date : {proc_date}", 0, 1, 'R')
            self.ln(5)

        def footer(self):
            self.set_y(-10)
            self.set_font('Arial', 'I', 6)
            self.cell(0, 5, f'Page {self.page_no()}/{{nb}}', 0, 0, 'C')

    pdf = PDF('P', 'mm', 'A4')
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    # --- Data Extraction and Formatting ---
    app_id = data.get('application_id', 'N/A')
    acct_no = data.get('AcctNo', 'N/A')
    owner_name = f"{data.get('first_name', '')} {data.get('last_name', '')}".strip().upper()
    bus_name = data.get('businessName', 'N/A').upper()
    bus_address = data.get('business_address', 'N/A')
    app_type = data.get('application_type', 'N/A')
    due_date = data.get('due_date', date.today()).strftime('%B %d, %Y')
    total_annual_due = data.get('total_annual_due', 0.00)
    
    # --- 1. Header Information ---
    pdf.set_font('Arial', '', 8)
    pdf.cell(20, 5, 'App No.:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, str(app_id).zfill(4), 0, 0)
    pdf.set_font('Arial', '', 8); pdf.set_x(120); pdf.cell(20, 5, 'Ownership:', 0); pdf.cell(30, 5, data.get('business_type', 'Single'), 0, 1)
    
    pdf.set_x(10); pdf.cell(20, 5, 'Tax Payer:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(100, 5, owner_name, 0, 1)

    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Commercial Name:', 0); pdf.set_font('Arial', 'B', 8); pdf.multi_cell(100, 4, bus_name, 0, 'L') 
    
    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Business Address:', 0); pdf.set_font('Arial', 'B', 8); pdf.multi_cell(100, 4, bus_address.upper(), 0, 'L')
    
    pdf.set_font('Arial', '', 8); pdf.set_x(10); pdf.cell(20, 5, 'Status:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, app_type.upper(), 0, 0)
    
    pdf.set_font('Arial', '', 8); pdf.set_x(120); pdf.cell(20, 5, 'Still No.:', 0); pdf.set_font('Arial', 'B', 8); pdf.cell(30, 5, acct_no, 0, 1)
    pdf.ln(5)

    # --- 2. Fee Details Table Header/Rows (Drawing logic simplified for brevity, use full version) ---
    pdf.set_fill_color(220, 220, 220); pdf.set_font('Arial', 'B', 7)
    col_widths = [15, 65, 25, 25, 25, 20]; headers = ['Code', 'Tax Description', 'TaxBase', 'Current Qtr Due', 'Annual Due', 'Period Cover']
    for w, h in zip(col_widths, headers): pdf.cell(w, 5, h, 1, 0, 'C', 1)
    pdf.ln()
    
    pdf.set_font('Arial', '', 7)
    fee_details = data.get('fee_details', [])
    for fee in fee_details:
        pdf.cell(15, 5, fee.get('Code', ''), 1); pdf.cell(65, 5, fee.get('TaxDescription', ''), 1)
        pdf.cell(25, 5, f"{fee.get('TaxBase', 0.00):,.2f}", 1, 0, 'R'); pdf.cell(25, 5, f"{fee.get('CurrentQtrDue', 0.00):,.2f}", 1, 0, 'R')
        pdf.cell(25, 5, f"{fee.get('AnnualDue', 0.00):,.2f}", 1, 0, 'R'); pdf.cell(20, 5, fee.get('PeriodCovered', ''), 1, 1, 'C')

    # --- 4. Summary Totals Section (Drawing logic simplified) ---
    pdf.ln(2); pdf.set_font('Arial', 'B', 8)
    w_label = 30; w_amount = 30; total_annual_due = data.get('total_annual_due', 0.00)
    pdf.cell(w_label, 5, 'Business Tax (A)', 1, 0, 'C'); pdf.cell(w_amount, 5, 'Regulatory Fees (A)', 1, 0, 'C')
    pdf.cell(w_amount, 5, 'Other Fees', 1, 0, 'C'); pdf.cell(w_label - 10, 5, 'Surcharge', 1, 0, 'C')
    pdf.cell(w_label - 10, 5, 'Interest', 1, 0, 'C'); pdf.set_font('Arial', 'B', 8); pdf.cell(w_label + 10, 5, 'Total Annual Due', 1, 1, 'C') 
    
    pdf.set_font('Arial', '', 8)
    pdf.cell(w_label, 5, f"{data.get('total_business_tax', 0.00):,.2f}", 1, 0, 'R') # ... (and so on for all summary rows)

    # --- 5. Installment Breakdown (Drawing logic simplified) ---
    pdf.ln(5); pdf.set_font('Arial', 'B', 8)
    w_qtr = 25; w_sa = 35
    pdf.cell(w_qtr * 3, 5, 'QUARTERLY DUES', 1, 0, 'C'); pdf.cell(w_sa * 2, 5, 'SEMI-ANNUAL', 1, 1, 'C')
    # ... (Drawing cells for Qtr/SA amounts) ...
    
    # --- Signature and Note Section (Drawing logic simplified) ---
    pdf.ln(10); pdf.set_font('Arial', 'B', 8)
    pdf.cell(0, 5, f"Balance to be paid / Renewal On or Before : {due_date}", 0, 1, 'C')
    
    pdf.ln(10); pdf.set_font('Arial', 'B', 8)
    or_info = f"Last Payment ORNO: {data.get('or_number', '_______')} [DATE: {data.get('date_paid', '_______')}] [AMOUNT: {total_annual_due:,.2f}]"
    pdf.multi_cell(0, 4, or_info, 0, 'L')
    
    return pdf.output(dest='S').encode('latin1')

@app.route("/api/user/application_payment_details", methods=["GET"])
def get_application_payment_details():
    user_id = request.args.get('user_id')
    if not user_id: 
        return jsonify({"status": "error", "message": "User ID is required."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 
        
        # Fetch data using the utility function defined above
        data = fetch_user_application_and_payment_status(user_id, cursor)
        
        if not data:
            # This handles the case where the user has no active applications
            return jsonify({"success": False, "message": "No relevant application found."}), 200 
        
        status = data['status']
        due_date_str = data['due_date']
        payment_date_str = data['date_paid']

        # Status Mapping Logic
        if status == 'Ready for Payment':
            status_detail = 'Pay to the Treasury Office'
            payment_instruction = f'Payment Due: {due_date_str}'
        elif status == 'Approved':
            status_detail = 'Approved by BPLO, awaiting assessment'
            payment_instruction = 'Awaiting Assessment'
        elif status == 'Payment Received':
            status_detail = 'Payment Confirmed'
            payment_instruction = f'Paid on: {payment_date_str}'
        else:
            status_detail = status # Pending Review, etc.
            payment_instruction = 'Processing...'
            
        return jsonify({
            "success": True,
            "application_id": data['application_id'],
            "business_name": data['businessName'],
            "status_detail": status_detail,
            "due_date": due_date_str,
            "payment_date": payment_date_str,
            "payment_instruction": payment_instruction
        }), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    finally:
        if conn: conn.close()

# --- MAIN EXECUTION BLOCK (FIXED) ---
if __name__ == "__main__":
    from admin_api import admin_bp
    
    app.register_blueprint(admin_bp)
    
    app.run(host="0.0.0.0", port=5000, debug=True)


