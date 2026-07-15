import streamlit as st

from utils.mongodb import (
    get_total_documents,
    get_storage_used,
    get_recent_documents
)

# def render_home():
#     st.markdown("""
#         <div class="topbar">
#           <div class="topbar-title">Home</div>
#           <div class="topbar-search">Search vault...</div>
#           <div class="avatar-sm">UN</div>
#         </div>
#     """, unsafe_allow_html=True)

#     # Status strip — indigo only
#     st.markdown("""
#         <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:1.75rem;">
#           <span class="badge badge-indigo">AES-256 active</span>
#           <span class="badge badge-indigo">MFA enabled</span>
#           <span class="badge badge-indigo">PIN set</span>
#           <span class="badge badge-indigo">AWS S3 connected</span>
#           <span class="badge badge-indigo">Session: 15 min timeout</span>
#         </div>
#     """, unsafe_allow_html=True)

#     # Only 2 stat cards — removed file integrity
#     c1, c2 = st.columns(2)
#     with c1:
#         st.markdown("""
#             <div class="stat-card">
#               <div class="stat-label">Total documents</div>
#               <div class="stat-val accent">3</div>
#               <div class="stat-sub">3 added this month</div>
#             </div>
#         """, unsafe_allow_html=True)
#     with c2:
#         st.markdown("""
#             <div class="stat-card">
#               <div class="stat-label">Storage used</div>
#               <div class="stat-val">10 <span style="font-size:16px">MB</span></div>
#               <div class="stat-sub">of 50 MB free tier</div>
#             </div>
#         """, unsafe_allow_html=True)

def render_home():

    total_docs = get_total_documents("demo_user")

    storage_bytes = get_storage_used("demo_user")

    storage_mb = round(storage_bytes / (1024 * 1024), 2)

    recent_docs = get_recent_documents("demo_user")

    st.markdown("""
        <div class="topbar">
            <div class="topbar-title">Home</div>
            <div class="topbar-search">Search vault...</div>
            <div class="avatar-sm">UN</div>
        </div>
    """, unsafe_allow_html=True)

    # Status strip
    st.markdown("""
        <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:1.75rem;">
            <span class="badge badge-indigo">AES-256 active</span>
            <span class="badge badge-indigo">MFA enabled</span>
            <span class="badge badge-indigo">PIN set</span>
            <span class="badge badge-indigo">AWS S3 connected</span>
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

    # ---------------- Recent Activity ----------------

    st.markdown(
        '<div class="section-title">Recent Activity</div>',
        unsafe_allow_html=True
    )

    if recent_docs:

        for doc in recent_docs:

            st.markdown(f"""
                <div class="doc-row">
                    <div style="flex:1;">
                        <div class="doc-name">
                            {doc["filename"]}
                        </div>

                        <div class="doc-meta">
                            Uploaded on {doc["uploaded_at"].strftime("%d %b %Y")}
                        </div>
                    </div>
                </div>
            """, unsafe_allow_html=True)

    else:

        st.info("No recent uploads.")

    # ---------------- Storage ----------------

    st.markdown(
        '<div class="section-title">Storage</div>',
        unsafe_allow_html=True
    )