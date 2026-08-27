import base64
import hashlib
import os
import secrets
from cryptography.fernet import Fernet


def generate_recovery_key():
    """A one-time-shown recovery key. Never stored in plaintext anywhere."""
    return secrets.token_urlsafe(18)  # ~24 url-safe characters


def _derive_fernet_key(recovery_key, salt):
    key = hashlib.pbkdf2_hmac("sha256", recovery_key.encode(), salt, 100_000)
    return base64.urlsafe_b64encode(key)


def encrypt_password_with_recovery_key(password, recovery_key):
    """
    Escrows the account password so it can be recovered later using ONLY the recovery key.
    We store the password (not a new one) because file encryption keys are derived from
    the ORIGINAL password — resetting to a new password would make existing files undecryptable.
    Returns (encrypted_password_bytes, salt_bytes) to be stored in the DB.
    """
    salt = os.urandom(16)
    fkey = _derive_fernet_key(recovery_key, salt)
    cipher = Fernet(fkey)
    encrypted = cipher.encrypt(password.encode())
    return encrypted, salt


def decrypt_password_with_recovery_key(encrypted_password, salt, recovery_key):
    """Returns the original account password if the recovery key is correct, else raises."""
    fkey = _derive_fernet_key(recovery_key, salt)
    cipher = Fernet(fkey)
    return cipher.decrypt(encrypted_password).decode()