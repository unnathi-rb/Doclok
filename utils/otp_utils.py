import random
import time
import os
import requests
from dotenv import load_dotenv

load_dotenv()

RESEND_API_KEY = os.getenv("RESEND_API_KEY")
SMTP_EMAIL = os.getenv("SMTP_EMAIL")

OTP_VALID_SECONDS = 300  # 5 minutes


def generate_otp():
    return str(random.randint(100000, 999999))


def send_otp_email(to_email, otp):
    subject = "Your DocLok verification code"
    body = f"""Hi,

Your DocLok login verification code is: {otp}

This code is valid for 5 minutes. If you did not try to log in, you can ignore this email.

— DocLok
"""

    response = requests.post(
        "https://api.resend.com/emails",
        headers={
            "Authorization": f"Bearer {RESEND_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "from": f"DocLok <{SMTP_EMAIL}>",
            "to": [to_email],
            "subject": subject,
            "text": body,
        },
        timeout=20,
    )

    if response.status_code not in (200, 201):
        raise Exception(f"Resend email failed: {response.text}")

    return True


def otp_expired(sent_at):
    if not sent_at:
        return True
    return (time.time() - sent_at) > OTP_VALID_SECONDS