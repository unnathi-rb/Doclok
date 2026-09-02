"""
Two kinds of tokens used by the API:

1. login_session_token — short-lived, tracks progress through the 3-step
   login flow (password -> OTP -> PIN) across stateless requests, since
   there's no browser session like Streamlit's st.session_state to rely on.
   Stored server-side in Mongo with a TTL, keyed by a random token string.

2. access_token (JWT) — issued only after all 3 steps succeed. Required
   on every authenticated endpoint (documents, security, profile).
"""
import os
import time
import secrets
import jwt
from utils.mongodb import db

login_sessions_collection = db["login_sessions"]

JWT_SECRET     = os.getenv("JWT_SECRET_KEY", "dev-secret-change-me")
JWT_ALGORITHM  = "HS256"
JWT_EXP_SECONDS = 60 * 60 * 12  # 12 hours

LOGIN_SESSION_TTL_SECONDS = 60 * 15  # 15 minutes to complete OTP + PIN steps


def create_login_session(email: str, user: dict) -> str:
    token = secrets.token_urlsafe(32)
    login_sessions_collection.update_one(
        {"_id": token},
        {"$set": {
            "email": email,
            "otp_verified": False,
            "generated_otp": None,
            "otp_sent_at": None,
            "created_at": time.time(),
        }},
        upsert=True
    )
    return token


def get_login_session(token: str):
    session = login_sessions_collection.find_one({"_id": token})
    if not session:
        return None
    if time.time() - session.get("created_at", 0) > LOGIN_SESSION_TTL_SECONDS:
        login_sessions_collection.delete_one({"_id": token})
        return None
    return session


def update_login_session(token: str, fields: dict):
    login_sessions_collection.update_one({"_id": token}, {"$set": fields})


def delete_login_session(token: str):
    login_sessions_collection.delete_one({"_id": token})


def create_access_token(email: str) -> str:
    payload = {
        "sub": email,
        "exp": time.time() + JWT_EXP_SECONDS,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str):
    """Returns the email if valid, raises jwt exceptions if not."""
    payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    return payload["sub"]