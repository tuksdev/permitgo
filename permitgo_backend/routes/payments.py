# routes/payments.py

from flask import Blueprint, request, jsonify
from permitgo_backend.services.db_utils import get_db_connection
from permitgo_backend.services.xendit_service import create_xendit_invoice # Assuming you create this service file
from datetime import datetime
import traceback

payment_bp = Blueprint('payments', __name__)

# ✅ CREATE PAYMENT
@payment_bp.route("/create", methods=["POST"])
def create_payment():
    data = request.get_json()
    print(f"📩 Received payment data: {data}")

    required_fields = ["user_id", "application_id", "amount", "email"] # Simplified fields
    if not all(field in data and data[field] for field in required_fields):
        return jsonify({"success": False, "message": "Missing required fields."}), 400

    application_id = int(data["application_id"])

    # Delegate to Xendit Service
    result = create_xendit_invoice(data, application_id)
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 400

# --- XENDIT REDIRECT HANDLERS (for payment completion/failure) ---

@payment_bp.route("/success", methods=["GET"])
def payment_success():
    application_id = request.args.get("application_id")
    # In a real app, you would verify the Xendit transaction ID here.
    
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE payments SET status = 'PAID', paid_date = NOW() WHERE application_id = %s", (application_id,))
        conn.commit()
        return f"Payment successful for Application ID {application_id}. You can close this window.", 200
    except Exception as e:
        print(f"Error updating payment status: {e}")
        return "Payment processed, but database update failed.", 500
    finally:
        if conn: conn.close()

@payment_bp.route("/failed", methods=["GET"])
def payment_failed():
    application_id = request.args.get("application_id")
    # In a real app, you would mark the status as FAILED or CANCELED
    return f"Payment failed for Application ID {application_id}. Please try again later.", 200