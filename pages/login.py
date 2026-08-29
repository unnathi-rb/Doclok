import streamlit as st
import time

from utils.mongodb import (
    register_user,
    login_user,
    verify_pin,
    update_pin
)
from utils.otp_utils import generate_otp, send_otp_email, otp_expired
from utils.recovery_utils import (
    generate_recovery_key,
    encrypt_password_with_recovery_key,
    decrypt_password_with_recovery_key,
)
from utils.mongodb import get_recovery_data
from utils.security_utils import is_locked_out, register_failed_attempt, reset_attempts

def render_login():
    step = st.session_state.auth_step
    # new: track whether user is on login or signup
    if "auth_mode" not in st.session_state:
        st.session_state.auth_mode = "login"

    # Reduce Streamlit's default top page padding so the card sits near the top
    st.markdown("""
        <style>
        .block-container { padding-top: 2rem !important; }
        .st-key-forgot_pw_wrap.st-key-forgot_pw_wrap.st-key-forgot_pw_wrap button,
        .st-key-back_recover_wrap.st-key-back_recover_wrap.st-key-back_recover_wrap button,
        .st-key-forgot_pin_wrap.st-key-forgot_pin_wrap.st-key-forgot_pin_wrap button {
            background: transparent !important;
            background-color: transparent !important;
            border: none !important;
            box-shadow: none !important;
            padding: 0 !important;
            width: auto !important;
            min-height: 0 !important;
        }
        .st-key-forgot_pw_wrap.st-key-forgot_pw_wrap.st-key-forgot_pw_wrap button *,
        .st-key-back_recover_wrap.st-key-back_recover_wrap.st-key-back_recover_wrap button *,
        .st-key-forgot_pin_wrap.st-key-forgot_pin_wrap.st-key-forgot_pin_wrap button * {
            color: #534AB7 !important;
            text-decoration: underline !important;
            font-size: 13px !important;
            font-weight: 400 !important;
        }
        </style>
    """, unsafe_allow_html=True)
    # center the card using columns — no full-page div needed
    col_l, col_c, col_r = st.columns([1, 1.2, 1])

    with col_c:
        # ── Logo ──────────────────────────────────────────────────────────
        st.markdown("""
            <div style="display:flex;align-items:center;gap:10px;margin-bottom:1.2rem;">
              <div style="width:38px;height:38px;background:#534AB7;border-radius:9px;
                          display:flex;align-items:center;justify-content:center;font-size:20px">🔒</div>
              <div style="font-size:22px;font-weight:600;color:#1E1B4B;letter-spacing:-0.4px">
                Doc<span style="color:#534AB7">Lok</span>
              </div>
            </div>
        """, unsafe_allow_html=True)

        # ── Mode toggle: Login / Sign Up ──────────────────────────────────
        mode = st.session_state.auth_mode
        t1, t2 = st.columns(2)
        with t1:
            if st.button("Login", key="mode_login", use_container_width=True):
                st.session_state.auth_mode = "login"
                st.session_state.auth_step = "password"
                st.rerun()
        with t2:
            if st.button("Sign Up", key="mode_signup", use_container_width=True):
                st.session_state.auth_mode = "signup"
                st.session_state.auth_step = "signup"
                st.rerun()

        st.markdown("<hr style='border:none;border-top:1px solid #E2E0F8;margin:.75rem 0 1.25rem'>", unsafe_allow_html=True)

        if st.session_state.get("session_expired"):
            st.warning("Your session expired due to inactivity. Please log in again.")
            del st.session_state["session_expired"]

        # ══════════════════════════════════════════
        # SIGN UP FLOW
        # ══════════════════════════════════════════
        if mode == "signup" and st.session_state.get("newly_created_recovery_key"):
            st.success("Account created successfully!")
            st.markdown("**Save your recovery key**")
            st.warning(
                "This key is shown only once and is never stored anywhere in plaintext. "
                "If you lose both your password and this key, your documents can never be recovered."
            )
            st.code(st.session_state.newly_created_recovery_key)

            if st.button("I've saved my recovery key — Continue to Login", key="btn_recovery_ack", use_container_width=True):
                del st.session_state["newly_created_recovery_key"]
                st.session_state.auth_mode = "login"
                st.session_state.auth_step = "password"
                st.rerun()

        elif mode == "signup":
            st.markdown("**Create your account**")
            st.caption("All your documents will be encrypted with a key derived from your password.")

            su_name  = st.text_input("Full name", placeholder="XYZ", key="su_name")
            su_email = st.text_input("Email address", placeholder="you@example.com", key="su_email")
            su_phone = st.text_input("Mobile number", placeholder="98765 43210", key="su_phone")

            st.markdown("<div style='height:4px'></div>", unsafe_allow_html=True)
            st.markdown("**Set your password**")
            st.caption("This also derives your encryption key — keep it safe.")
            su_pass1 = st.text_input("Password", type="password", key="su_pass1")
            su_pass2 = st.text_input("Confirm password", type="password", key="su_pass2")

            st.markdown("<div style='height:4px'></div>", unsafe_allow_html=True)
            st.markdown("**Set your access PIN**")
            st.caption("Required for every upload, view, and download.")
            su_pin1  = st.text_input("4-digit PIN", type="password", max_chars=4, key="su_pin1")
            su_pin2  = st.text_input("Confirm PIN", type="password", max_chars=4, key="su_pin2")

            if st.button("Create account", key="btn_signup", use_container_width=True):
                # Validation
                if not all([su_name, su_email, su_phone, su_pass1, su_pass2, su_pin1, su_pin2]):
                    st.error("Please fill in all fields.")
                elif su_pass1 != su_pass2:
                    st.error("Passwords do not match.")
                elif len(su_pass1) < 8:
                    st.error("Password must be at least 8 characters.")
                elif su_pin1 != su_pin2:
                    st.error("PINs do not match.")
                elif len(su_pin1) < 4:
                    st.error("PIN must be 4 digits.")
                else:

                    recovery_key = generate_recovery_key()
                    recovery_enc, recovery_salt = encrypt_password_with_recovery_key(su_pass1, recovery_key)
                            # Normalize phone to E.164 format before saving
                    clean_phone = su_phone.strip().replace(" ", "").replace("-", "")
                    if clean_phone and not clean_phone.startswith("+"):
                        clean_phone = "+91" + clean_phone.lstrip("0")
                    created = register_user(
                        su_name,
                        su_email,
                        su_pass1,
                        su_pin1,
                        clean_phone,
                        recovery_enc,
                        recovery_salt,
                    )

                    if created:
                        st.session_state.newly_created_recovery_key = recovery_key
                        st.rerun()

                    else:
                        st.error("An account with this email already exists.")
            st.markdown("<div style='text-align:center;font-size:12px;color:#6B67A8;margin-top:.75rem'>Already have an account? <span style='color:#534AB7;cursor:pointer'>Log in above</span></div>", unsafe_allow_html=True)

        # ══════════════════════════════════════════
        # LOGIN FLOW — 3 steps
        # ══════════════════════════════════════════
        else:
            # Step indicator
            steps_html = "<div style='display:flex;gap:0;margin-bottom:1.25rem;border:1px solid #E2E0F8;border-radius:8px;overflow:hidden'>"
            for label, s in [("Password","password"),("OTP","otp"),("PIN","pin")]:
                active = "background:#EEEDFE;color:#3C3489;font-weight:500" if step == s else "color:#6B67A8"
                steps_html += f"<div style='flex:1;padding:7px;text-align:center;font-size:12px;{active}'>{label}</div>"
            steps_html += "</div>"
            st.markdown(steps_html, unsafe_allow_html=True)

            # ── Step 1: Password ──────────────────────────────────────────
            if step == "password":
                st.markdown("<span style='background:#EEEDFE;color:#3C3489;font-size:11px;font-weight:500;padding:3px 12px;border-radius:20px'>Step 1 of 3 — identity</span>", unsafe_allow_html=True)
                st.markdown("<div style='height:10px'></div>", unsafe_allow_html=True)
                st.markdown("**Welcome back**")
                st.caption("Sign in to access your secure vault")

                email    = st.text_input("Email address", placeholder="you@example.com", key="login_email")
                password = st.text_input("Password", type="password", key="login_password")

                if st.button("Continue", key="btn_password", use_container_width=True):

                    user = login_user(
                        email,
                        password
                    )

                    if user:

                        st.session_state.user = user
                        st.session_state.user_email = email
                        st.session_state.user_name = user["name"]

                        # Guard: skip re-sending if one was already sent very recently
                        # (prevents duplicate emails from double-clicks/rapid reruns)
                        last_sent = st.session_state.get("otp_sent_at", 0)
                        if time.time() - last_sent > 5:
                            st.session_state.otp_sent_at = time.time()  # set BEFORE the slow network call
                            otp = generate_otp()
                            try:
                                send_otp_email(email, otp)
                                st.session_state.generated_otp = otp
                            except Exception as e:
                                st.error(f"Could not send OTP: {e}")
                                st.stop()

                        st.session_state.auth_step = "otp"
                        st.rerun()

                    else:

                        st.error("Invalid email or password.")

                st.markdown('<div class="ghost-link-marker"></div>', unsafe_allow_html=True)
                with st.container(key="forgot_pw_wrap"):
                    if st.button("Forgot password? Use recovery key", key="btn_forgot_pw", use_container_width=False):
                        st.session_state.auth_step = "recover"
                        st.rerun()

            # ── Step: Password recovery ─────────────────────────────────
            elif step == "recover":
                st.markdown("**Recover your password**")
                st.caption("Enter your email and the recovery key you saved at signup.")

                rec_email = st.text_input("Email address", key="rec_email")
                rec_key   = st.text_input("Recovery key", key="rec_key")

                if st.button("Recover password", key="btn_recover", use_container_width=True):
                    data = get_recovery_data(rec_email)
                    if not data:
                        st.error("No recovery key was set up for this account.")
                    else:
                        try:
                            recovered = decrypt_password_with_recovery_key(
                                data["recovery_password_enc"],
                                data["recovery_salt"],
                                rec_key,
                            )
                            st.success(f"Your password is: **{recovered}**")
                            st.caption("Use it to log in below. Anyone who saw this recovery key also now knows your password.")
                        except Exception:
                            st.error("Incorrect recovery key.")

                st.markdown('<div class="ghost-link-marker"></div>', unsafe_allow_html=True)
                with st.container(key="back_recover_wrap"):
                    if st.button("Back to login", key="btn_back_recover", use_container_width=True):
                        st.session_state.auth_step = "password"
                        st.rerun()

            # ── Step 2: OTP ───────────────────────────────────────────────
            elif step == "otp":
                st.markdown("<span style='background:#EEEDFE;color:#3C3489;font-size:11px;font-weight:500;padding:3px 12px;border-radius:20px'>Step 2 of 3 — verification</span>", unsafe_allow_html=True)
                st.markdown("<div style='height:10px'></div>", unsafe_allow_html=True)
                st.markdown("**Check your email**")

                email = st.session_state.user_email
                masked = email[:2] + "***@" + email.split("@")[1]
                st.caption(f"OTP sent to **{masked}**")

                otp_input = st.text_input("Enter 6-digit OTP", max_chars=6, key="otp_val", placeholder="e.g. 483192")

                # visual OTP boxes
                boxes = ""
                for i in range(6):
                    ch  = otp_input[i] if i < len(otp_input) else "&nbsp;"
                    cls = "background:#EEEDFE;border-color:#7F77DD" if i < len(otp_input) else ""
                    boxes += f"<div style='width:42px;height:48px;border:1px solid #E2E0F8;border-radius:6px;{cls};display:flex;align-items:center;justify-content:center;font-family:monospace;font-size:18px;font-weight:500;color:#3C3489'>{ch}</div>"
                st.markdown(f"<div style='display:flex;gap:8px;justify-content:center;margin:.75rem 0'>{boxes}</div>", unsafe_allow_html=True)

                col1, col2 = st.columns(2)
                with col1:
                    if st.button("Back", key="btn_back_otp", use_container_width=True):
                        st.session_state.auth_step = "password"
                        st.rerun()
                with col2:
                    if st.button("Verify OTP", key="btn_otp", use_container_width=True):
                        if otp_expired(st.session_state.get("otp_sent_at")):
                            st.error("OTP expired. Please resend a new one.")
                        elif otp_input == st.session_state.get("generated_otp"):
                            st.session_state.auth_step = "pin"
                            st.rerun()
                        else:
                            st.error("Incorrect OTP.")

                st.markdown("<div style='height:6px'></div>", unsafe_allow_html=True)

                RESEND_COOLDOWN_SECONDS = 30
                elapsed = time.time() - st.session_state.get("otp_sent_at", 0)
                can_resend = elapsed >= RESEND_COOLDOWN_SECONDS

                if not can_resend:
                    st.caption(f"You can resend in {int(RESEND_COOLDOWN_SECONDS - elapsed)}s")

                if st.button("Resend OTP", key="btn_resend_otp", use_container_width=True, disabled=not can_resend):
                    st.session_state.otp_sent_at = time.time()  # set BEFORE the slow network call
                    new_otp = generate_otp()
                    try:
                        send_otp_email(email, new_otp)
                        st.session_state.generated_otp = new_otp
                        st.success("A new OTP has been sent.")
                    except Exception as e:
                        st.error(f"Could not resend OTP: {e}")

            # ── Step 3: PIN ───────────────────────────────────────────────
            elif step == "pin":
                st.markdown("<span style='background:#EEEDFE;color:#3C3489;font-size:11px;font-weight:500;padding:3px 12px;border-radius:20px'>Step 3 of 3 — access PIN</span>", unsafe_allow_html=True)
                st.markdown("<div style='height:10px'></div>", unsafe_allow_html=True)

                if st.session_state.get("resetting_pin"):

                    st.markdown("**Set a new PIN**")
                    st.caption("You've already verified your password and OTP, so this is safe to change now.")

                    new_pin1 = st.text_input("New 4-digit PIN", type="password", max_chars=4, key="reset_pin1")
                    new_pin2 = st.text_input("Confirm new PIN", type="password", max_chars=4, key="reset_pin2")

                    c1, c2 = st.columns(2)
                    with c1:
                        if st.button("Cancel", key="btn_cancel_pin_reset", use_container_width=True):
                            st.session_state.resetting_pin = False
                            st.rerun()
                    with c2:
                        if st.button("Save new PIN", key="btn_save_new_pin", use_container_width=True):
                            if new_pin1 != new_pin2:
                                st.error("PINs do not match.")
                            elif len(new_pin1) < 4:
                                st.error("PIN must be 4 digits.")
                            else:
                                update_pin(st.session_state.user_email, new_pin1)
                                reset_attempts("login_pin")
                                st.session_state.resetting_pin = False
                                st.session_state.authenticated = True
                                st.session_state.auth_step = "password"
                                st.rerun()

                else:

                    st.markdown("**Enter your PIN**")
                    st.caption("Your 4-digit vault access PIN")

                    pin_input = st.text_input("Access PIN", type="password", max_chars=4, key="pin_val", placeholder="****")

                    locked, remaining = is_locked_out("login_pin")
                    if locked:
                        st.error(f"Too many incorrect PIN attempts. Try again in {remaining}s.")

                    # PIN dot indicators
                    dots = ""
                    for i in range(4):
                        filled = "background:#534AB7;border-color:#534AB7" if i < len(pin_input) else "background:#fff"
                        dots += f"<div style='width:13px;height:13px;border-radius:50%;border:1.5px solid #AFA9EC;{filled}'></div>"
                    st.markdown(f"<div style='display:flex;gap:10px;justify-content:center;margin:.75rem 0'>{dots}</div>", unsafe_allow_html=True)

                    col1, col2 = st.columns(2)
                    with col1:
                        if st.button("Back", key="btn_back_pin", use_container_width=True):
                            st.session_state.auth_step = "otp"
                            st.rerun()
                    with col2:
                        if st.button("Enter Vault", key="btn_pin", use_container_width=True, disabled=locked):

                            if verify_pin(
                                st.session_state.user_email,
                                pin_input
                            ):

                                reset_attempts("login_pin")
                                st.session_state.authenticated = True
                                st.session_state.auth_step = "password"
                                st.rerun()

                            else:

                                register_failed_attempt("login_pin")
                                st.error("Incorrect PIN.")

                    st.markdown('<div class="ghost-link-marker"></div>', unsafe_allow_html=True)
                    with st.container(key="forgot_pin_wrap"):
                        if st.button("Forgot PIN?", key="btn_forgot_pin", use_container_width=False):
                            st.session_state.resetting_pin = True
                            st.rerun()