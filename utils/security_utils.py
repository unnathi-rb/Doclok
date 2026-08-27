import time
import streamlit as st

MAX_ATTEMPTS    = 5
LOCKOUT_SECONDS = 60


def is_locked_out(lockout_key):
    """Returns (locked: bool, seconds_remaining: int) for a given lockout key."""
    lock_until = st.session_state.get(f"{lockout_key}_lock_until", 0)
    remaining = lock_until - time.time()
    if remaining > 0:
        return True, int(remaining)
    return False, 0


def register_failed_attempt(lockout_key):
    """Call this on every wrong PIN entry. Locks out after MAX_ATTEMPTS."""
    attempts = st.session_state.get(f"{lockout_key}_attempts", 0) + 1
    st.session_state[f"{lockout_key}_attempts"] = attempts

    if attempts >= MAX_ATTEMPTS:
        st.session_state[f"{lockout_key}_lock_until"] = time.time() + LOCKOUT_SECONDS
        st.session_state[f"{lockout_key}_attempts"] = 0

    return attempts


def reset_attempts(lockout_key):
    """Call this on a successful PIN entry to clear the counter."""
    st.session_state[f"{lockout_key}_attempts"] = 0
    st.session_state[f"{lockout_key}_lock_until"] = 0