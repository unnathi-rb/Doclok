import cv2
import numpy as np


def preprocess_image(image_bytes):
    """
    Improves OCR accuracy by:
    - Converting to grayscale
    - Removing noise
    - Applying adaptive thresholding (binarization)
    Returns preprocessed image as PNG bytes.
    """
    np_arr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if img is None:
        # Not a decodable raster image (shouldn't happen for jpg/png uploads) — return original
        return image_bytes

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    denoised = cv2.fastNlMeansDenoising(gray, h=10)

    thresholded = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,
        C=15,
    )

    success, encoded = cv2.imencode(".png", thresholded)

    if not success:
        return image_bytes

    return encoded.tobytes()