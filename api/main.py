import base64
import time

from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt as pyjwt

from utils.mongodb import (
    register_user,
    login_user,
    verify_pin,
    update_pin,
    verify_password,
    get_recovery_data,
    get_all_documents,
    save_document_metadata,
    delete_document,
    users_collection,
    create_folder,
    get_folders,
    delete_folder,
    delete_user,
)
from utils.otp_utils import generate_otp, send_otp_email, otp_expired
from utils.recovery_utils import (
    generate_recovery_key,
    encrypt_password_with_recovery_key,
    decrypt_password_with_recovery_key,
)
from utils.encryption import encrypt_file, decrypt_file, encrypt_filename, decrypt_filename
from utils.hash_utils import generate_hash, verify_sha256
from utils.s3_utils import upload_to_s3, download_from_s3, delete_from_s3

from api.auth import (
    create_login_session,
    get_login_session,
    update_login_session,
    delete_login_session,
    create_access_token,
    decode_access_token,
)
from api.lockout import is_locked_out, register_failed_attempt, reset_attempts

import uuid


app = FastAPI(title="DocLok API")
security_scheme = HTTPBearer()


# ── Auth dependency for protected endpoints ──────────────────────────────
def get_current_user_email(creds: HTTPAuthorizationCredentials = Depends(security_scheme)) -> str:
    try:
        return decode_access_token(creds.credentials)
    except pyjwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Session expired, please log in again.")
    except pyjwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid session token.")


# ══════════════════════════════════════════════════════════════════════
# REQUEST MODELS
# ══════════════════════════════════════════════════════════════════════

class SignupRequest(BaseModel):
    name: str
    email: str
    phone: str
    password: str
    pin: str


class LoginPasswordRequest(BaseModel):
    email: str
    password: str


class VerifyOtpRequest(BaseModel):
    login_session_token: str
    otp: str


class ResendOtpRequest(BaseModel):
    login_session_token: str


class VerifyPinRequest(BaseModel):
    login_session_token: str
    pin: str


class RecoverPasswordRequest(BaseModel):
    email: str
    recovery_key: str


class UpdatePinRequest(BaseModel):
    current_pin: str
    new_pin: str


class DocPinRequest(BaseModel):
    pin: str


class DocDecryptRequest(BaseModel):
    password: str


# ══════════════════════════════════════════════════════════════════════
# AUTH ROUTES
# ══════════════════════════════════════════════════════════════════════

@app.post("/auth/signup")
def signup(req: SignupRequest):
    if len(req.password) < 8:
        raise HTTPException(400, "Password must be at least 8 characters.")
    if len(req.pin) < 4:
        raise HTTPException(400, "PIN must be 4 digits.")

    clean_phone = req.phone.strip().replace(" ", "").replace("-", "")
    if clean_phone and not clean_phone.startswith("+"):
        clean_phone = "+91" + clean_phone.lstrip("0")

    recovery_key = generate_recovery_key()
    recovery_enc, recovery_salt = encrypt_password_with_recovery_key(req.password, recovery_key)

    created = register_user(
        req.name, req.email, req.password, req.pin,
        clean_phone, recovery_enc, recovery_salt,
    )

    if not created:
        raise HTTPException(409, "An account with this email already exists.")

    return {
        "recovery_key": recovery_key,
        "message": "Save this recovery key now — it will not be shown again."
    }


@app.post("/auth/login/password")
def login_password(req: LoginPasswordRequest):
    user = login_user(req.email, req.password)
    if not user:
        raise HTTPException(401, "Invalid email or password.")

    token = create_login_session(req.email, user)

    otp = generate_otp()
    try:
        send_otp_email(req.email, otp)
    except Exception as e:
        raise HTTPException(502, f"Could not send OTP: {e}")

    update_login_session(token, {
        "generated_otp": otp,
        "otp_sent_at": time.time(),
    })

    return {"login_session_token": token, "message": "OTP sent to your email."}


@app.post("/auth/login/resend-otp")
def resend_otp(req: ResendOtpRequest):
    session = get_login_session(req.login_session_token)
    if not session:
        raise HTTPException(400, "Login session expired. Please start over.")

    last_sent = session.get("otp_sent_at") or 0
    if time.time() - last_sent < 5:
        return {"message": "OTP already sent recently."}

    otp = generate_otp()
    update_login_session(req.login_session_token, {
        "generated_otp": otp,
        "otp_sent_at": time.time(),
    })
    try:
        send_otp_email(session["email"], otp)
    except Exception as e:
        raise HTTPException(502, f"Could not resend OTP: {e}")

    return {"message": "A new OTP has been sent."}


@app.post("/auth/login/verify-otp")
def verify_otp(req: VerifyOtpRequest):
    session = get_login_session(req.login_session_token)
    if not session:
        raise HTTPException(400, "Login session expired. Please start over.")

    if otp_expired(session.get("otp_sent_at")):
        raise HTTPException(400, "OTP expired. Please resend a new one.")

    if req.otp != session.get("generated_otp"):
        raise HTTPException(400, "Incorrect OTP.")

    update_login_session(req.login_session_token, {"otp_verified": True})
    return {"message": "OTP verified. Proceed to PIN."}


@app.post("/auth/login/verify-pin")
def verify_pin_route(req: VerifyPinRequest):
    session = get_login_session(req.login_session_token)
    if not session:
        raise HTTPException(400, "Login session expired. Please start over.")
    if not session.get("otp_verified"):
        raise HTTPException(400, "OTP not verified yet.")

    email = session["email"]
    lockout_key = f"login_pin_{email}"

    locked, remaining = is_locked_out(lockout_key)
    if locked:
        raise HTTPException(429, f"Too many incorrect PIN attempts. Try again in {remaining}s.")

    if verify_pin(email, req.pin):
        reset_attempts(lockout_key)
        delete_login_session(req.login_session_token)
        access_token = create_access_token(email)
        return {"access_token": access_token}
    else:
        register_failed_attempt(lockout_key)
        raise HTTPException(401, "Incorrect PIN.")


@app.post("/auth/forgot-pin")
def forgot_pin(login_session_token: str, new_pin: str):
    """Only usable mid-login, after password + OTP already verified."""
    session = get_login_session(login_session_token)
    if not session or not session.get("otp_verified"):
        raise HTTPException(400, "Password and OTP must be verified first.")
    if len(new_pin) < 4:
        raise HTTPException(400, "PIN must be 4 digits.")

    email = session["email"]
    update_pin(email, new_pin)
    reset_attempts(f"login_pin_{email}")
    delete_login_session(login_session_token)

    access_token = create_access_token(email)
    return {"access_token": access_token, "message": "PIN updated."}


@app.post("/auth/recover-password")
def recover_password(req: RecoverPasswordRequest):
    data = get_recovery_data(req.email)
    if not data:
        raise HTTPException(404, "No recovery key was set up for this account.")

    try:
        password = decrypt_password_with_recovery_key(
            data["recovery_password_enc"], data["recovery_salt"], req.recovery_key
        )
    except Exception:
        raise HTTPException(401, "Incorrect recovery key.")

    return {"password": password}


# ══════════════════════════════════════════════════════════════════════
# DOCUMENT ROUTES (require Authorization: Bearer <access_token>)
# ══════════════════════════════════════════════════════════════════════

@app.post("/documents/upload")
def upload_document(
    pin: str = Form(...),
    password: str = Form(...),
    file: UploadFile = File(...),
    folder: str = Form(None),
    email: str = Depends(get_current_user_email),
):
    lockout_key = f"upload_pin_{email}"
    locked, remaining = is_locked_out(lockout_key)
    if locked:
        raise HTTPException(429, f"Too many incorrect PIN attempts. Try again in {remaining}s.")

    if not verify_pin(email, pin):
        register_failed_attempt(lockout_key)
        raise HTTPException(401, "Incorrect PIN.")
    reset_attempts(lockout_key)

    if not verify_password(email, password):
        raise HTTPException(401, "Incorrect password.")

    file_data = file.file.read()

    encrypted_data = encrypt_file(file_data, password)
    encrypted_name = encrypt_file(file.filename.encode(), password)
    display_name_enc = encrypt_filename(file.filename)
    file_hash = generate_hash(encrypted_data)

    encrypted_filename = f"{email}_{uuid.uuid4().hex}.enc"
    upload_to_s3(encrypted_data, encrypted_filename)
    salt = encrypted_data[:16]

    save_document_metadata(
        user_id=email,
        encrypted_name=encrypted_name,
        display_name_enc=display_name_enc,
        encrypted_filename=encrypted_filename,
        s3_key=encrypted_filename,
        file_hash=file_hash,
        salt=salt,
        size=len(file_data),
        folder=(folder if folder else None),
    )

    return {"message": "Document uploaded successfully.", "s3_key": encrypted_filename}


@app.get("/documents")
def list_documents(email: str = Depends(get_current_user_email)):
    documents = get_all_documents(email)
    result = []
    for doc in documents:
        try:
            shown_name = decrypt_filename(doc["display_name_enc"])
        except Exception:
            shown_name = "Encrypted document"
        result.append({
            "id": doc["s3_key"],
            "display_name": shown_name,
            "size_kb": round(doc["size"] / 1024, 1),
            "date": doc["uploaded_at"].isoformat(),
            "status": doc["status"],
            "folder": doc.get("folder"),
        })
    return result


class CreateFolderRequest(BaseModel):
    name: str


@app.post("/folders")
def create_folder_route(req: CreateFolderRequest, email: str = Depends(get_current_user_email)):
    name = req.name.strip()
    if not name:
        raise HTTPException(400, "Folder name can't be empty.")
    created = create_folder(email, name)
    if not created:
        raise HTTPException(409, "A folder with that name already exists.")
    return {"message": "Folder created.", "name": name}


@app.get("/folders")
def list_folders_route(email: str = Depends(get_current_user_email)):
    return get_folders(email)


@app.delete("/folders/{name}")
def delete_folder_route(name: str, email: str = Depends(get_current_user_email)):
    delete_folder(email, name)
    return {"message": "Folder deleted. Its documents were moved back to the root."}


@app.post("/documents/{doc_id}/verify-pin")
def verify_document_pin(doc_id: str, req: DocPinRequest, email: str = Depends(get_current_user_email)):
    lockout_key = f"doc_pin_{email}_{doc_id}"
    locked, remaining = is_locked_out(lockout_key)
    if locked:
        raise HTTPException(429, f"Too many attempts. Try again in {remaining}s.")

    if verify_pin(email, req.pin):
        reset_attempts(lockout_key)
        return {"message": "PIN verified."}
    else:
        register_failed_attempt(lockout_key)
        raise HTTPException(401, "Incorrect PIN.")


@app.post("/documents/{doc_id}/decrypt")
def decrypt_document(doc_id: str, req: DocDecryptRequest, email: str = Depends(get_current_user_email)):
    documents = get_all_documents(email)
    doc = next((d for d in documents if d["s3_key"] == doc_id), None)
    if not doc:
        raise HTTPException(404, "Document not found.")

    if not verify_password(email, req.password):
        raise HTTPException(401, "Incorrect password. Cannot decrypt file.")

    try:
        real_name = decrypt_file(doc["encrypted_name"], req.password).decode()
    except Exception:
        raise HTTPException(401, "Could not decrypt this document's filename with that password.")

    encrypted_data = download_from_s3(doc_id)

    if not verify_sha256(encrypted_data, doc["hash"]):
        raise HTTPException(409, "Tampered — this file's integrity check failed.")

    decrypted_data = decrypt_file(encrypted_data, req.password)

    return {
        "filename": real_name,
        "file_base64": base64.b64encode(decrypted_data).decode(),
        "integrity": "verified",
    }


@app.delete("/documents/{doc_id}")
def delete_doc(doc_id: str, email: str = Depends(get_current_user_email)):
    documents = get_all_documents(email)
    doc = next((d for d in documents if d["s3_key"] == doc_id), None)
    if not doc:
        raise HTTPException(404, "Document not found.")

    delete_from_s3(doc_id)
    delete_document(doc_id)
    return {"message": "Document deleted successfully."}


# ══════════════════════════════════════════════════════════════════════
# SECURITY & PROFILE ROUTES
# ══════════════════════════════════════════════════════════════════════

@app.post("/security/update-pin")
def security_update_pin(req: UpdatePinRequest, email: str = Depends(get_current_user_email)):
    if not verify_pin(email, req.current_pin):
        raise HTTPException(401, "Your current PIN is incorrect.")
    if len(req.new_pin) < 4:
        raise HTTPException(400, "PIN must be 4 digits.")

    update_pin(email, req.new_pin)
    return {"message": "PIN updated successfully."}


@app.delete("/account")
def delete_account_route(email: str = Depends(get_current_user_email)):
    for doc in get_all_documents(email):
        try:
            delete_from_s3(doc["s3_key"])
        except Exception:
            pass
        delete_document(doc["s3_key"])
    delete_user(email)
    return {"message": "Account and all data deleted."}


@app.get("/profile")
def get_profile(email: str = Depends(get_current_user_email)):
    user = users_collection.find_one({"email": email})
    if not user:
        raise HTTPException(404, "User not found.")
    return {
        "name": user["name"],
        "email": user["email"],
        "phone": user.get("phone", ""),
    }