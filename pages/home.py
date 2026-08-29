import streamlit as st

from utils.mongodb import (
    get_total_documents,
    get_storage_used,
)


def render_home():

    user_email = st.session_state.user_email
    user_name  = st.session_state.get("user_name", "User")
    initials   = "".join([p[0].upper() for p in user_name.split()[:2]]) or "U"

    total_docs = get_total_documents(user_email)

    storage_bytes = get_storage_used(user_email)

    storage_mb = round(storage_bytes / (1024 * 1024), 2)

    st.markdown(f"""
        <div class="topbar">
            <div class="topbar-title">Home</div>
            <div class="avatar-sm">{initials}</div>
        </div>
    """, unsafe_allow_html=True)

    # Status strip
    st.markdown("""
        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:1.75rem;">
            <span class="badge badge-indigo">Session: 15 min timeout</span>
        </div>
    """, unsafe_allow_html=True)

    c1, c2 = st.columns(2)

    with c1:
        st.markdown(f"""
            <div class="stat-card">
                <div class="stat-label">Total Documents</div>
                <div class="stat-val accent">{total_docs}</div>
                <div class="stat-sub">Stored securely in your vault</div>
            </div>
        """, unsafe_allow_html=True)

    with c2:
        st.markdown(f"""
            <div class="stat-card">
                <div class="stat-label">Storage Used</div>
                <div class="stat-val">{storage_mb}
                    <span style="font-size:16px">MB</span>
                </div>
                <div class="stat-sub">of 50 MB free tier</div>
            </div>
        """, unsafe_allow_html=True)