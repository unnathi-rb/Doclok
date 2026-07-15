import hashlib


def generate_hash(file_data: bytes):

    sha256 = hashlib.sha256()

    sha256.update(file_data)

    return sha256.hexdigest()


def verify_sha256(file_data: bytes, stored_hash: str):
    current_hash = generate_hash(file_data)
    return current_hash == stored_hash

def hash_password(password):
    return hashlib.sha256(
        password.encode()
    ).hexdigest()