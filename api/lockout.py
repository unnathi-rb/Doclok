"""
PIN attempt lockout for the API — mirrors utils/security_utils.py's logic
(5 attempts, 60-second lockout), but persisted in MongoDB instead of
st.session_state, since a REST API has no browser session to lean on.
"""
import time
from utils.mongodb import db

lockouts_collection = db["lockouts"]

MAX_ATTEMPTS    = 5
LOCKOUT_SECONDS = 60


def is_locked_out(lockout_key: str):
    """Returns (locked: bool, seconds_remaining: int)."""
    record = lockouts_collection.find_one({"_id": lockout_key})
    if not record:
        return False, 0
    remaining = record.get("lock_until", 0) - time.time()
    if remaining > 0:
        return True, int(remaining)
    return False, 0


def register_failed_attempt(lockout_key: str):
    """Call on every wrong PIN entry. Locks out after MAX_ATTEMPTS."""
    record = lockouts_collection.find_one({"_id": lockout_key}) or {"attempts": 0}
    attempts = record.get("attempts", 0) + 1

    update = {"attempts": attempts}
    if attempts >= MAX_ATTEMPTS:
        update["lock_until"] = time.time() + LOCKOUT_SECONDS
        update["attempts"] = 0

    lockouts_collection.update_one(
        {"_id": lockout_key},
        {"$set": update},
        upsert=True
    )
    return attempts


def reset_attempts(lockout_key: str):
    """Call on a successful PIN entry to clear the counter."""
    lockouts_collection.update_one(
        {"_id": lockout_key},
        {"$set": {"attempts": 0, "lock_until": 0}},
        upsert=True
    )