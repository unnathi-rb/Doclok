from pymongo import MongoClient
from dotenv import load_dotenv
import os
import certifi
from datetime import datetime
from pymongo import DESCENDING
from utils.hash_utils import hash_password


load_dotenv()

client = MongoClient(os.getenv("MONGODB_URI"), tlsCAFile=certifi.where())

db = client["doclok"]

documents_collection = db["documents"]

users_collection = db["users"]
def save_document_metadata(
    user_id,
    encrypted_name,
    display_name_enc,
    encrypted_filename,
    s3_key,
    file_hash,
    salt,
    size,
):
    document = {
        "user_id": user_id,
        "encrypted_name": encrypted_name,
        "display_name_enc": display_name_enc,
        "encrypted_filename": encrypted_filename,
        "s3_key": s3_key,
        "hash": file_hash,
        "salt": salt.hex(),
        "size": size,
        "status": "Verified",
        "uploaded_at": datetime.utcnow(),
    }

    result = documents_collection.insert_one(document)

    print("Metadata saved!")
    print("Inserted ID:", result.inserted_id)
    

def get_all_documents(user_id):
    return list(
        documents_collection.find(
            {"user_id": user_id}
        )
    )


def get_recent_documents(user_id, limit=5):
    return list(
        documents_collection.find(
            {"user_id": user_id}
        ).sort(
            "uploaded_at",
            DESCENDING
        ).limit(limit)
    )


def get_total_documents(user_id):
    return documents_collection.count_documents(
        {"user_id": user_id}
    )


def get_storage_used(user_id):
    docs = documents_collection.find(
        {"user_id": user_id}
    )

    total = 0

    for doc in docs:
        total += doc["size"]

    return total

try:
    client.admin.command("ping")
    print("✅ MongoDB Connected Successfully!")
except Exception as e:
    print("❌ MongoDB Connection Failed")
    print(e)
def delete_document(s3_key):
    documents_collection.delete_one(
        {"s3_key": s3_key}
    )
    
def register_user(
    name,
    email,
    password,
    pin,
    phone=None,
    recovery_password_enc=None,
    recovery_salt=None,
):

    existing_user = users_collection.find_one(
        {"email": email}
    )

    if existing_user:
        return False

    users_collection.insert_one({

        "name": name,

        "email": email,

        "phone": phone,

        "password": hash_password(password),

        "pin": hash_password(pin),

        "recovery_password_enc": recovery_password_enc,

        "recovery_salt": recovery_salt,

    })

    return True

def get_recovery_data(email):
    user = users_collection.find_one({"email": email})
    if not user or not user.get("recovery_password_enc"):
        return None
    return {
        "recovery_password_enc": user["recovery_password_enc"],
        "recovery_salt": user["recovery_salt"],
    }
def login_user(
    email,
    password
):

    return users_collection.find_one({

        "email": email,

        "password": hash_password(password)

    })
def verify_pin(
    email,
    pin
):

    user = users_collection.find_one(
        {"email": email}
    )

    if not user:
        return False

    return user["pin"] == hash_password(pin)

def update_pin(
    email,
    new_pin
):

    users_collection.update_one(
        {"email": email},
        {"$set": {"pin": hash_password(new_pin)}}
    )

    return True

def verify_password(
    email,
    password
):

    user = users_collection.find_one(
        {"email": email}
    )

    if not user:
        return False

    return user["password"] == hash_password(password)