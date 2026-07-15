import streamlit as st

def render_profile():
    st.markdown('<div style="margin-left:0px">', unsafe_allow_html=True)

    st.markdown("""
        <div class="topbar">
          <div class="topbar-title">Profile</div>
          <div class="avatar-sm">UN</div>
        </div>
    """, unsafe_allow_html=True)

    # Profile card — uses CSS variables not hardcoded colors
    st.markdown("""
        <div class="stat-card" style="margin-bottom:1.25rem;display:flex;align-items:center;gap:1.5rem;">
          <div style="width:64px;height:64px;border-radius:50%;
                      background:var(--indigo-50);
                      display:flex;align-items:center;justify-content:center;
                      font-size:22px;font-weight:700;color:var(--indigo-800);
                      flex-shrink:0;border:2px solid var(--border);">RS</div>
          <div>
            <div style="font-size:18px;font-weight:700;color:var(--text-main);">unnathi</div>
            <div style="font-size:13px;color:var(--text-muted);margin-top:2px;">unnathi@example.com</div>
            <span class="badge badge-indigo" style="margin-top:8px;display:inline-flex;">Personal vault</span>
          </div>
        </div>
    """, unsafe_allow_html=True)

    st.markdown('<div class="section-title">Account details</div>', unsafe_allow_html=True)

    with st.form("profile_form"):
        col1, col2 = st.columns(2)
        with col1:
            st.text_input("Full name", value="Unnathi")
        with col2:
            st.text_input("Email", value="unnathi@example.com")
        col3, col4 = st.columns(2)
        with col3:
            st.text_input("Mobile number", value="+91 11111 00000")
        with col4:
            st.selectbox("Account type", ["Personal", "Student", "Professional"])

        if st.form_submit_button("Save changes"):
            st.success("Profile updated.")

    st.markdown('<div class="section-title">Danger zone</div>', unsafe_allow_html=True)

    st.markdown("""
        <div style="border:1px solid var(--danger-tx);border-radius:10px;
                    padding:1rem 1.3rem;background:var(--danger-bg);">
          <div style="font-size:13px;font-weight:600;color:var(--danger-tx);margin-bottom:.3rem;">
            Delete account
          </div>
          <div style="font-size:12px;color:var(--danger-tx);opacity:0.8;margin-bottom:.75rem;">
            Permanently deletes all your documents and account data. Cannot be undone.
          </div>
        </div>
    """, unsafe_allow_html=True)

    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    if st.button("Delete my account"):
        st.error("Disabled in demo.")

    st.markdown("</div>", unsafe_allow_html=True)