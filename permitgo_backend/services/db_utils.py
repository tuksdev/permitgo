# services/db_utils.py
import pymysql
import pymysql.cursors

# This import assumes you are using the solution from the "ImportError" fix
# and have the project structured correctly.
from permitgo_backend.utils.constant import DB_CONFIG

def get_db_connection(dict_cursor=False):
    """Returns a new DB connection, optionally with a DictCursor."""
    cursor_type = pymysql.cursors.DictCursor if dict_cursor else pymysql.cursors.Cursor
    try:
        # Use DictCursor for fetching dictionary results
        return pymysql.connect(cursorclass=cursor_type, **DB_CONFIG)
    except Exception as e:
        print(f"❌ Database Connection Error: {e}")
        # Re-raise the exception so the calling route can catch it
        raise