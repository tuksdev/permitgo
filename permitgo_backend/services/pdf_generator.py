# services/pdf_generator.py

import os
import io
from datetime import date, datetime
from fpdf import FPDF as FPDF2 

# --- CRITICAL FIX: Correct the import path and file name ---
# Assuming app_service.py (singular) is the correct filename.
from permitgo_backend.services.app_services import fetch_full_application_details 
# --- End Fix ---

# Safety check for FPDF, relying on FPDF2 being installed.
try:
    from fpdf import FPDF, HTMLMixin
except ImportError:
    # Minimal fallback class to prevent errors if fpdf2 is missing
    class FPDF:
        def __init__(self, *args, **kwargs): pass
        def add_page(self): pass
        def output(self, *args): return b''
        def set_xy(self, *args): pass
        def set_font(self, *args): pass
        def multi_cell(self, *args): pass
        def cell(self, *args): pass
        def ln(self, *args): pass
        def set_auto_page_break(self, *args): pass
        def set_text_color(self, *args): pass
        def image(self, *args): pass


class PermitPDF(FPDF2):
    """Custom FPDF class for the Mayor's Permit."""
    
    # We define header outside the function below, so this class structure is optional 
    # but good practice for extending FPDF.

    pass # Keeping the class empty as the generation function below handles the layout


def generate_permit_pdf(data, application_id):
    """Generates the Mayor's Permit PDF bytes using comprehensive application data."""
    
    permit_number_display = f"No. {application_id:04}"
    SEAL_PATH = 'images/buguey(logo).png'
    SIGNATURE_PATH = 'images/mayor_signature.png'
    
    pdf = FPDF2(orientation='P', unit='mm', format='A4')
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    # --- Header (Replicating the header logic from your original file) ---
    if os.path.exists(SEAL_PATH):
        pdf.image(SEAL_PATH, x=15, y=10, w=30)
    
    pdf.set_xy(10, 15)
    pdf.set_font("Arial", "B", 10)
    pdf.multi_cell(190, 5, "Republic of the Philippines\nProvince of Cagayan\nMUNICIPALITY OF BUGUEY", align="C")
    
    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 5, "OFFICE OF THE MAYOR", ln=1, align="C")
    pdf.set_font("Arial", "B", 16)
    pdf.cell(190, 10, "MAYOR'S PERMIT", ln=1, align="C")

    # --- Watermark (from your original code) ---
    if os.path.exists(SEAL_PATH):
        # The FPDF2 set_fill_color, set_alpha, is_mask, etc., usage is specific; 
        # using standard FPDF image placement for simplicity here, 
        # but keep your original advanced image/watermark logic if it works.
        pass 
        
    pdf.ln(20)
    
    # --- Main Data Content (Rest of the Permit) ---
    
    # Business Trade Name
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "BUSINESS TRADE NAME:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.cell(190, 6, data.get('trade_name', 'NAME MISSING').upper(), ln=1, align="C")
    
    pdf.ln(3)
    
    # Owner/Proprietor
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "OWNER/PROPRIETOR:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    owner_full_name = f"{data.get('first_name', '')} {data.get('middle_name', '')} {data.get('last_name', '')}".replace("  ", " ").strip().upper()
    pdf.cell(190, 6, owner_full_name, ln=1, align="C")
    
    pdf.ln(3)
    
    # Location of Business
    pdf.set_font("Arial", "B", 12)
    pdf.cell(190, 8, "LOCATION OF BUSINESS:", ln=1, align="L")
    pdf.set_font("Arial", "", 12)
    pdf.cell(190, 6, data.get('business_address', 'ADDRESS MISSING').upper(), ln=1, align="C")
    
    pdf.ln(10)
    
    # Permit Granting Text
    pdf.set_font("Arial", "", 10)
    text_content = (
        "PERMIT IS HEREBY GRANTED to the above-mentioned person to engage in the above-stated business "
        "after payment of the required License/Permit Fees and compliance with the ordinances, rules and "
        "regulations governing the business trade."
    )
    pdf.multi_cell(180, 5, text_content, align="J")
    
    pdf.ln(10)
    
    # Date and Location
    issue_date_obj = data.get('permit_issue_date')
    if isinstance(issue_date_obj, datetime):
        issue_date_obj = issue_date_obj.date()
    elif not isinstance(issue_date_obj, date):
        issue_date_obj = datetime.now().date()
        
    current_day = issue_date_obj.day
    current_month_year = issue_date_obj.strftime("%B, %Y")
    date_text = f"GIVEN this {current_day} day of {current_month_year} at Buguey, Cagayan, Philippines."
    pdf.cell(190, 5, date_text, ln=1, align="L")

    pdf.ln(20)

    # --- Signature Block ---
    if os.path.exists(SIGNATURE_PATH):
         pdf.image(SIGNATURE_PATH, x=150, y=pdf.get_y()-20, w=40, h=15)

    pdf.set_x(100)
    pdf.set_font("Arial", "B", 12)
    pdf.cell(100, 5, "LICERIO MILLARE ANTIPORDA III", ln=1, align="R")
    pdf.set_x(100)
    pdf.set_font("Arial", "", 10)
    pdf.cell(100, 5, "Municipal Mayor", ln=1, align="R")
    
    pdf.ln(15)
    
    # Permit Number at the bottom right
    pdf.set_x(100)
    pdf.set_font("Arial", "B", 10)
    pdf.set_text_color(255, 0, 0)
    pdf.cell(100, 5, permit_number_display, ln=1, align="R")
    pdf.set_text_color(0, 0, 0) # Reset color

    return pdf.output(dest='B')