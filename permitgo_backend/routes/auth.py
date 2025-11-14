# routes/auth.py

from flask import Blueprint, request, jsonify
from permitgo_backend.services.db_utils import get_db_connection
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql.cursors
import pymysql.err
import traceback

auth_bp = Blueprint('auth', __name__)

# ✅ SIGN UP
@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.json
    required = ["first_name", "last_name", "email", "password", "mobile_number"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    password_hash = generate_password_hash(data["password"])
    conn = None
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
        if conn: conn.close()

# ✅ SIGN IN
@auth_bp.route("/signin", methods=["POST"])
def signin():
    data = request.json
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"status": "error", "message": "Email and password are required"}), 400

    conn = None
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
        if conn: conn.close()
        
# --- FORGOT PASSWORD ROUTE (email verification) ---
@auth_bp.route("/forgot_password", methods=["POST"])
def forgot_password():
    data = request.json
    email = data.get("email")
    
    if not email:
        return jsonify({"status": "error", "message": "Email is required to reset password"}), 400

    conn = None
    try:
        conn = get_db_connection(dict_cursor=True)
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM users WHERE email=%s", (email,))
        user_data = cursor.fetchone()
        
        if user_data:
            return jsonify({"status": "success", "message": "Email verified.", "user_id": user_data["user_id"]}), 200
        else:
            return jsonify({"status": "error", "message": "Email address not found."}), 404

    except Exception as e:
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"An unexpected server error occurred: {str(e)}"}), 500
    finally:
        if conn: conn.close()

# --- RESET PASSWORD ROUTE ---
@auth_bp.route("/reset_password", methods=["POST"])
def reset_password():
    data = request.json
    email = data.get("email")
    new_password = data.get("new_password")

    if not email or not new_password:
        return jsonify({"status": "error", "message": "Email and new password are required"}), 400

    conn = None
    try:
        new_password_hash = generate_password_hash(new_password)
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("UPDATE users SET password_hash = %s WHERE email = %s", (new_password_hash, email))
        conn.commit()
        
        if cursor.rowcount == 0:
            return jsonify({"status": "error", "message": "User not found or password was not changed."}), 404

        return jsonify({"status": "success", "message": "Your password has been successfully updated."}), 200

    except Exception as e:
        if conn: conn.rollback()
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"An unexpected server error occurred: {str(e)}"}), 500
    finally:
        if conn: conn.close()