# utils/file_handler.py
from permitgo_backend.utils.constant import ALLOWED_EXTENSIONS

def allowed_file(filename):
    """Checks if the file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS