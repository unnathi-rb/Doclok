import re

PII_PATTERNS = {
    "aadhaar": re.compile(r"\b\d{4}\s?\d{4}\s?\d{4}\b"),
    "pan":     re.compile(r"\b[A-Z]{5}[0-9]{4}[A-Z]\b"),
    "email":   re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"),
    "phone":   re.compile(r"\b(?:\+91[-\s]?)?[6-9]\d{9}\b"),
    "card":    re.compile(r"\b(?:\d[ -]*?){13,16}\b"),
}


def detect_sensitive_fields(text):
    """Returns a dict of field_type -> list of matches found in the text."""
    if not text:
        return {}

    found = {}
    for label, pattern in PII_PATTERNS.items():
        matches = pattern.findall(text)
        if matches:
            found[label] = matches
    return found


def _partial_mask(match):
    """Masks all but the last 4 alphanumeric characters of a match, preserving spacing/format."""
    chars = list(match.group())
    visible = 4
    seen = 0
    for i in range(len(chars) - 1, -1, -1):
        if chars[i].isalnum():
            if seen < visible:
                seen += 1
            else:
                chars[i] = "X"
    return "".join(chars)


def mask_sensitive_text(text):
    """Returns a copy of text with sensitive fields partially masked, e.g. 1234 5678 9012 -> XXXX XXXX 9012."""
    if not text:
        return text

    masked = text
    for pattern in PII_PATTERNS.values():
        masked = pattern.sub(_partial_mask, masked)
    return masked