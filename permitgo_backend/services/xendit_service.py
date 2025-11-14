# services/xendit_service.py

import requests
from datetime import datetime
from .db_utils import get_db_connection # Relative import to db_utils
from permitgo_backend.utils.constant import XENDIT_SECRET_KEY, XENDIT_INVOICE_URL, REDIRECT_BASE_URL # Absolute import
import traceback

def create_xendit_invoice(data, application_id):
    """Handles the API call to Xendit, inserts pending payment, and updates the DB."""
    
    amount = float(data["amount"])
    email = data["email"]
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 1. Insert pending record
        cursor.execute("INSERT INTO payments (user_id, application_id, amount, status) VALUES (%s, %s, %s, 'PENDING')", 
                       (data["user_id"], application_id, amount))
        conn.commit()

        # 2. Build Xendit payload
        invoice_data = {
            "external_id": f"APP-{application_id}-{int(datetime.now().timestamp())}",
            "amount": amount,
            "payer_email": email,
            "description": "Business Permit Application Fee",
            # Use the correct blueprint URLs for redirects
            "success_redirect_url": f"{REDIRECT_BASE_URL}/api/payments/success?application_id={application_id}",
            "failure_redirect_url": f"{REDIRECT_BASE_URL}/api/payments/failed?application_id={application_id}"
        }

        # 3. Send to Xendit API
        response = requests.post(
            XENDIT_INVOICE_URL,
            auth=(XENDIT_SECRET_KEY, ""),
            json=invoice_data
        )
        xendit_response = response.json()
        
        invoice_url = xendit_response.get("invoice_url")
        invoice_id = xendit_response.get("id")

        if not invoice_url:
            raise Exception(f"Xendit Error: {xendit_response.get('message', 'No URL received')}")

        # 4. Update DB with invoice details
        cursor.execute("UPDATE payments SET checkout_url = %s, maya_transaction_id = %s WHERE application_id = %s", 
                       (invoice_url, invoice_id, application_id))
        conn.commit()

        return {"success": True, "checkout_url": invoice_url}

    except Exception as e:
        print(f"❌ Error in create_xendit_invoice: {traceback.format_exc()}")
        if conn: conn.rollback()
        return {"success": False, "message": f"Payment failure: {str(e)}"}
    finally:
        if conn: conn.close()