import streamlit as st

NAV_ITEMS = [
    ("Home",         "Home"),
    ("Upload",       "Upload"),
    ("My Documents", "My Documents"),
    ("Security",     "Security"),
]

def render_sidebar():
    current = st.session_state.current_page
    dark    = st.session_state.dark_mode

    user_name = st.session_state.get("user_name", "User")
    initials  = "".join([p[0].upper() for p in user_name.split()[:2]]) or "U"

    st.markdown("""
        <style>
        section[data-testid="stSidebar"] div[data-testid="stButton"] {
            margin-top: 0px !important;
            margin-bottom: 0px !important;
        }
        section[data-testid="stSidebar"] div[data-testid="element-container"] {
            margin-bottom: 0px !important;
        }
        </style>
    """, unsafe_allow_html=True)

    with st.sidebar:
        # Logo
        st.markdown("""
            <div style="display:flex;align-items:center;gap:10px;padding:1rem 0 1.25rem 0;">
              <div style="width:34px;height:34px;background:#534AB7;border-radius:8px;
                          display:flex;align-items:center;justify-content:center;
                          font-size:18px;flex-shrink:0;">
                <span style="color:white;font-weight:700;font-size:14px">DL</span>
              </div>
              <div style="font-size:20px;font-weight:700;color:var(--text-main);">
                Doc<span style="color:#534AB7;">Lok</span>
              </div>
            </div>
        """, unsafe_allow_html=True)

        st.markdown("<hr style='margin:0 0 0.5rem 0;border:none;border-top:1px solid var(--border)'>", unsafe_allow_html=True)

        # Nav items
        for label, display in NAV_ITEMS:
            is_active = current == label
            if is_active:
                st.markdown(f"""
                    <div style="
                        background:var(--indigo-50);
                        border-left:3px solid #534AB7;
                        border-radius:0 8px 8px 0;
                        padding:10px 14px;
                        margin:2px -1rem 2px -1rem;
                        font-size:14px;font-weight:600;
                        color:#534AB7;">
                      {display}
                    </div>
                """, unsafe_allow_html=True)
            else:
                if st.button(display, key=f"nav_{label}", use_container_width=True):
                    st.session_state.current_page = label
                    st.rerun()

        st.markdown("<hr style='margin:.6rem 0;border:none;border-top:1px solid var(--border)'>", unsafe_allow_html=True)
# User info — name + round icon, with a "View profile" action instead
        # of a separate Profile nav item / static "Personal vault" label
        st.markdown(f"""
            <div style="display:flex;align-items:center;gap:10px;padding:6px 0;">
              <div style="width:34px;height:34px;border-radius:50%;
                          background:var(--indigo-50);
                          display:flex;align-items:center;justify-content:center;
                          font-size:12px;font-weight:700;color:#3C3489;flex-shrink:0;">{initials}</div>
              <div style="font-size:13px;font-weight:600;color:var(--text-main);">{user_name}</div>
            </div>
        """, unsafe_allow_html=True)

        if st.button("View profile", key="nav_view_profile", use_container_width=True):
            st.session_state.current_page = "Profile"
            st.rerun()

        
        st.markdown("<hr style='margin:.6rem 0;border:none;border-top:1px solid var(--border)'>", unsafe_allow_html=True)
        
        # Dark / Light toggle
        toggle_label = "Light Mode" if dark else "Dark Mode"
        if st.button(toggle_label, key="toggle_theme", use_container_width=True):
            st.session_state.dark_mode = not st.session_state.dark_mode
            st.rerun()

        if st.button("Logout", key="nav_logout", use_container_width=True):
            for key in list(st.session_state.keys()):
                del st.session_state[key]
            st.rerun()
            
                