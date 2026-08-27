import streamlit as st

from utils.mongodb import verify_pin, update_pin

SECURITY_ITEMS = [
    {
        "title": "File encryption — AES-256",
        "desc": "Every file is encrypted using a 256-bit key before it is saved. The key comes from your own password so only you can open your files — not even the server can read them.",
        "status": "Active",
    },
    {
        "title": "Two-step login (OTP)",
        "desc": "After entering your password, a one-time code is sent to your email. Even if someone has your password, they cannot log in without that code.",
        "status": "Enabled",
    },
    {
        "title": "Access PIN",
        "desc": "A 4-digit PIN is required every time you view, upload, or download a file. This adds an extra lock even when you are already logged in.",
        "status": "Set",
    },
    {
        "title": "Tamper detection — SHA-256",
        "desc": "Every file gets a unique fingerprint when saved. Each time you open or download it, the fingerprint is checked. If anything changed you will be warned immediately.",
        "status": "All files verified",
    },
    {
        "title": "Automatic logout",
        "desc": "If you have not done anything for 15 minutes, you will be logged out automatically. This protects your vault on shared or public devices.",
        "status": "15 min timeout",
    },
]

def render_security():
    user_email = st.session_state.user_email
    user_name  = st.session_state.get("user_name", "User")
    initials   = "".join([p[0].upper() for p in user_name.split()[:2]]) or "U"

    st.markdown(f"""
        <div class="topbar">
          <div class="topbar-title">Security</div>
          <div class="avatar-sm">{initials}</div>
        </div>
    """, unsafe_allow_html=True)

    # ── Change PIN — on top ───────────────────────────────────────────────
    st.markdown('<div class="section-title">Change your access PIN</div>', unsafe_allow_html=True)

    with st.form("change_pin_form"):
        col1, col2, col3 = st.columns(3)
        with col1:
            current_pin = st.text_input("Current PIN", type="password", max_chars=4, placeholder="****")
        with col2:
            new_pin     = st.text_input("New PIN",     type="password", max_chars=4, placeholder="****")
        with col3:
            confirm_pin = st.text_input("Confirm PIN", type="password", max_chars=4, placeholder="****")

        if st.form_submit_button("Update PIN", use_container_width=False):
            if not verify_pin(user_email, current_pin):
                st.error("Your current PIN is incorrect.")
            elif new_pin != confirm_pin:
                st.error("The new PINs you entered do not match.")
            elif len(new_pin) < 4:
                st.error("PIN must be exactly 4 digits.")
            else:
                update_pin(user_email, new_pin)
                st.success("PIN updated successfully.")

    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    # ── Security overview ─────────────────────────────────────────────────
    st.markdown('<div class="section-title">Security overview</div>', unsafe_allow_html=True)

    for item in SECURITY_ITEMS:
        st.markdown(f"""
            <div class="sec-card">
              <div style="flex:1">
                <div class="sec-card-title">{item['title']}</div>
                <div class="sec-card-desc">{item['desc']}</div>
                <span class="badge badge-indigo" style="margin-top:10px;display:inline-flex">
                  {item['status']}
                </span>
              </div>
            </div>
        """, unsafe_allow_html=True)