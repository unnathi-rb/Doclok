import streamlit as st

from utils.mongodb import (
    register_user,
    login_user,
    verify_pin
)
DEMO_OTP = "123456"
def render_login():
    step = st.session_state.auth_step
    # new: track whether user is on login or signup
    if "auth_mode" not in st.session_state:
        st.session_state.auth_mode = "login"

    # center the card using columns — no full-page div needed
    col_l, col_c, col_r = st.columns([1, 1.2, 1])

    with col_c:
        # ── Logo ──────────────────────────────────────────────────────────
        st.markdown("""
            <div style="display:flex;align-items:center;gap:10px;margin-bottom:1.8rem;margin-top:2rem">
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

        # ══════════════════════════════════════════
        # SIGN UP FLOW
        # ══════════════════════════════════════════
        if mode == "signup":
            st.markdown("**Create your account**")
            st.caption("All your documents will be encrypted with a key derived from your password.")

            su_name  = st.text_input("Full name", placeholder="Unnathi", key="su_name")
            su_email = st.text_input("Email address", placeholder="you@example.com", key="su_email")
            su_phone = st.text_input("Mobile number (for OTP)", placeholder="+91 98765 43210", key="su_phone")

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

                    created = register_user(
                        su_name,
                        su_email,
                        su_pass1,
                        su_pin1
                    )

                    if created:
                        st.success("Account created successfully!")

                        st.session_state.auth_mode = "login"
                        st.session_state.auth_step = "password"
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
            for label, s in [("🔑 Password","password"),("📱 OTP","otp"),("🔐 PIN","pin")]:
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

                email    = st.text_input("Email address", value="unnathi@example.com", key="login_email")
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

                        st.session_state.auth_step = "otp"
                        st.rerun()

                    else:

                        st.error("Invalid email or password.")

                st.markdown("<div style='text-align:center;font-size:12px;color:#6B67A8;margin-top:.75rem'>Forgot password? <span style='color:#534AB7'>Use recovery key</span></div>", unsafe_allow_html=True)

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
                        if otp_input == DEMO_OTP:
                            st.session_state.auth_step = "pin"
                            st.rerun()
                        else:
                            st.error(f"Wrong OTP. Demo: {DEMO_OTP}")

                st.markdown(f"<div style='text-align:center;font-size:12px;color:#6B67A8;margin-top:.75rem'>Did not receive it? <span style='color:#534AB7'>Resend OTP</span></div>", unsafe_allow_html=True)

            # ── Step 3: PIN ───────────────────────────────────────────────
            elif step == "pin":
                st.markdown("<span style='background:#EEEDFE;color:#3C3489;font-size:11px;font-weight:500;padding:3px 12px;border-radius:20px'>Step 3 of 3 — access PIN</span>", unsafe_allow_html=True)
                st.markdown("<div style='height:10px'></div>", unsafe_allow_html=True)
                st.markdown("**Enter your PIN**")
                st.caption("Your 4-digit vault access PIN")

                pin_input = st.text_input("Access PIN", type="password", max_chars=4, key="pin_val", placeholder="****")

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
                    if st.button("Enter Vault", key="btn_pin", use_container_width=True):

                        if verify_pin(
                            st.session_state.user_email,
                            pin_input
                        ):

                            st.session_state.authenticated = True
                            st.session_state.auth_step = "password"
                            st.rerun()

                        else:

                            st.error("Incorrect PIN.")