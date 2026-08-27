import random
import smtplib
import time
import os
import email.utils
from email.mime.text import MIMEText
from dotenv import load_dotenv

load_dotenv()

SMTP_EMAIL        = os.getenv("SMTP_EMAIL")
SMTP_APP_PASSWORD = os.getenv("SMTP_APP_PASSWORD")

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

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = f"DocLok <{SMTP_EMAIL}>"
    msg["To"] = to_email
    msg["Reply-To"] = SMTP_EMAIL
    msg["Date"] = email.utils.formatdate(localtime=True)
    msg["Message-ID"] = email.utils.make_msgid(domain="doclok.local")

    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls()
        server.login(SMTP_EMAIL, SMTP_APP_PASSWORD)
        server.sendmail(SMTP_EMAIL, to_email, msg.as_string())

    return True


def otp_expired(sent_at):
    if not sent_at:
        return True
    return (time.time() - sent_at) > OTP_VALID_SECONDS