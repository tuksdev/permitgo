# services/app_service.py
from permitgo_backend.services.db_utils import get_db_connection
import pymysql.cursors

def fetch_application_data_details(application_id, cursor):
    """
    Fetches comprehensive application data (Taxpayer, Application, Details, Activities, Lessor).
    Uses the provided cursor which MUST be a DictCursor.
    """
    
    # Base Query (Original complex join query)
    cursor.execute("""
        SELECT 
            ba.application_id, ba.status, ba.application_type, ba.application_date,
            ba.tin_no, ba.mode_of_payment, ba.business_type,
            t.first_name, t.last_name, t.trade_name, t.businessName,  
            ad.business_address, ad.is_rented
        FROM business_applications ba
        JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
        JOIN application_details ad ON ba.application_id = ad.application_id
        WHERE ba.application_id = %s;
    """, (application_id,))
    
    data = cursor.fetchone()
    if not data:
        return None

    # Fetch Lessor Details (if rented)
    if data.get('is_rented') == 'Rented':
        cursor.execute("SELECT lessor_name, monthly_rent FROM lessors WHERE application_id = %s", (application_id,))
        data['lessor'] = cursor.fetchone()
    else:
        data['lessor'] = None

    # Fetch Business Activities 
    cursor.execute("SELECT line_of_business, capitalization FROM business_activities WHERE application_id = %s", (application_id,))
    data['activities'] = cursor.fetchall()
    
    return data

# Your other utility functions (e.g., fetch_taxpayer_by_id) also belong here.
def fetch_taxpayer_by_id(taxpayer_id, cursor):
    """
    Fetches taxpayer details by taxpayer_id using the provided cursor.
    """
    cursor.execute("""
                   SELECT taxpayer_id, last_name, first_name, middle_name, account_number, trade_name, has_tax_incentive, tax_incentive_entity, businessName        
        FROM taxpayers
        WHERE taxpayer_id = %s
    """, (taxpayer_id,))
    return cursor.fetchone()

def fetch_lessor_by_application_id(application_id, cursor):
     """Fetches a single lessor record using the foreign key application_id (Used by Admin forms)."""
     cursor.execute("""
        SELECT lessor_id, lessor_name, lessor_address, lessor_email, lessor_mobile, monthly_rent
        FROM lessors 
        WHERE application_id = %s
   """, (application_id,))
     return cursor.fetchone()

def fetch_application_data_details(application_id, cursor):
    """
    NOTE: This appears to be an older/simplified version of fetch_full_application_details 
    from your previous code. Keeping it here for compatibility if other routes use it.
    """
    cursor.execute("""
        SELECT 
             ba.application_id, ba.status, ba.application_type, ba.application_date,
             ba.tin_no, ba.mode_of_payment, ba.business_type,
             t.first_name, t.last_name, t.trade_name, t.businessName,  
             ad.business_address, ad.is_rented
         FROM business_applications ba
         JOIN taxpayers t ON ba.taxpayer_id = t.taxpayer_id
         JOIN application_details ad ON ba.application_id = ad.application_id
         WHERE ba.application_id = %s;
    """, (application_id,))
    
    data = cursor.fetchone()
    if not data:
        return None

    if data.get('is_rented') == 'Rented':
        cursor.execute("SELECT lessor_name, monthly_rent FROM lessors WHERE application_id = %s", (application_id,))
        data['lessor'] = cursor.fetchone()
    else:
        data['lessor'] = None

    cursor.execute("SELECT line_of_business, capitalization FROM business_activities WHERE application_id = %s", (application_id,))
    data['activities'] = cursor.fetchall()
    
    return data