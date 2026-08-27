import os
from twilio.rest import Client
from dotenv import load_dotenv

load_dotenv()

_account_sid = os.getenv("TWILIO_ACCOUNT_SID")
_auth_token  = os.getenv("TWILIO_AUTH_TOKEN")
_from_whatsapp = os.getenv("TWILIO_WHATSAPP_NUMBER")

_client = Client(_account_sid, _auth_token)


def send_otp_sms(to_phone, otp):
    _client.messages.create(
        body=f"Your DocLok verification code is: {otp}. Valid for 5 minutes.",
        from_=_from_whatsapp,
        to=f"whatsapp:{to_phone}",
    )
    return True