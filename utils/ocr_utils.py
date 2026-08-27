import io
import os
import shutil
import pytesseract
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

# pytesseract is just a Python wrapper — it needs the real Tesseract program installed
# separately. On Windows this usually isn't on PATH by default, so we point to it explicitly.
_configured_path = os.getenv("TESSERACT_CMD")

if _configured_path and os.path.exists(_configured_path):
    pytesseract.pytesseract.tesseract_cmd = _configured_path
else:
    _default_windows_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.name == "nt" and os.path.exists(_default_windows_path):
        pytesseract.pytesseract.tesseract_cmd = _default_windows_path
    else:
        _found = shutil.which("tesseract")
        if _found:
            pytesseract.pytesseract.tesseract_cmd = _found


def extract_text_from_image(image_bytes):
    """OCR a (preferably preprocessed) image using local Tesseract. No data leaves the server."""
    image = Image.open(io.BytesIO(image_bytes))
    text = pytesseract.image_to_string(image)
    return text.strip()


def extract_text_from_pdf(pdf_bytes):
    """Extract text from a PDF: embedded text first, local OCR fallback for scanned pages."""
    import fitz  # PyMuPDF
    from utils.preprocessing_utils import preprocess_image

    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    text_parts = []

    for page in doc:
        page_text = page.get_text().strip()
        if page_text:
            text_parts.append(page_text)
        else:
            pix = page.get_pixmap()
            img_bytes = pix.tobytes("png")
            preprocessed = preprocess_image(img_bytes)
            text_parts.append(extract_text_from_image(preprocessed))

    doc.close()
    return "\n".join(text_parts)
