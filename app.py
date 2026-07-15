import streamlit as st
from components.sidebar import render_sidebar
from pages.login import render_login
from pages.home import render_home
from pages.upload import render_upload
from pages.my_documents import render_my_documents
from pages.security import render_security
from pages.profile import render_profile

st.set_page_config(
    page_title="DocLok — Cloud Document Vault",
    page_icon="",
    layout="wide",
    initial_sidebar_state="expanded",
)

defaults = {
    "authenticated": False,
    "auth_step": "password",
    "auth_mode": "login",
    "current_page": "Home",
    "user_email": "",
    "dark_mode": False,
    "selected_doc": None,
    "doc_pin_ok": False,
    "doc_password_ok": False,
}
for k, v in defaults.items():
    if k not in st.session_state:
        st.session_state[k] = v

# Hide Streamlit auto nav
st.markdown("""
<style>
section[data-testid="stSidebar"] ul { display: none !important; }
section[data-testid="stSidebarNavItems"] { display: none !important; }
div[data-testid="stSidebarNavSeparator"] { display: none !important; }
section[data-testid="stSidebar"] > div:first-child { padding-top: 0 !important; }
</style>
""", unsafe_allow_html=True)

# Always load light CSS as base
with open("assets/style_light.css", encoding="utf-8") as f:
    st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

# Load dark CSS on top if dark mode is on
if st.session_state.dark_mode:
    with open("assets/dark.css", encoding="utf-8") as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

# Router
if not st.session_state.authenticated:
    render_login()
else:
    render_sidebar()
    page = st.session_state.current_page
    if page == "Home":           render_home()
    elif page == "Upload":       render_upload()
    elif page == "My Documents": render_my_documents()
    elif page == "Security":     render_security()
    elif page == "Profile":      render_profile()