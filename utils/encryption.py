import os
import base64

from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.fernet import Fernet

from cryptography.fernet import Fernet
import hashlib
import base64


def generate_key(password):

    key = hashlib.sha256(
        password.encode()
    ).digest()

    return base64.urlsafe_b64encode(key)


def decrypt_file(
    encrypted_data,
    password
):

    key = generate_key(password)

    cipher = Fernet(key)

    return cipher.decrypt(
        encrypted_data
    )
    
def generate_key(password: str, salt: bytes):

    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )

    key = base64.urlsafe_b64encode(
        kdf.derive(password.encode())
    )

    return key


def encrypt_file(file_data: bytes, password: str):

    salt = os.urandom(16)

    key = generate_key(password, salt)

    cipher = Fernet(key)

    encrypted_data = cipher.encrypt(file_data)

    return salt + encrypted_data


def decrypt_file(encrypted_file_data: bytes, password: str):

    salt = encrypted_file_data[:16]

    encrypted_data = encrypted_file_data[16:]

    key = generate_key(password, salt)

    cipher = Fernet(key)

    decrypted_data = cipher.decrypt(encrypted_data)

    return decrypted_data