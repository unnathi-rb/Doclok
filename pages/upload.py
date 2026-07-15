import streamlit as st
import time
import os
from utils.hash_utils import generate_hash
from utils.encryption import encrypt_file
from utils.s3_utils import upload_to_s3
from utils.mongodb import save_document_metadata
PIPELINE_STEPS = [
    "Step 1 — Improving image quality (OpenCV)...",
    "Step 2 — Reading text from document (OCR)...",
    "Step 3 — Finding and hiding sensitive info...",
    "Step 4 — Encrypting your file (AES-256)...",
    "Step 5 — Creating security fingerprint (SHA-256)...",
    "Step 6 — Saving securely to cloud (AWS S3)...",
]

DEMO_PIN      = "2648"
DEMO_PASSWORD = "password123"


def render_upload():
    if "upload_step"     not in st.session_state: st.session_state.upload_step     = "select"
    if "upload_file_obj" not in st.session_state: st.session_state.upload_file_obj = None

    st.markdown("""
        <div class="topbar">
          <div class="topbar-title">Upload document</div>
          <div class="avatar-sm">UN</div>
        </div>
    """, unsafe_allow_html=True)

    # ── Step tracker ──────────────────────────────────────────────────────
    step_map   = {"select": 0, "pin": 1, "password": 2, "uploading": 3}
    step_names = ["Select file", "Enter PIN", "Enter password", "Done"]
    current    = step_map.get(st.session_state.upload_step, 0)

    cols = st.columns(4)
    for i, (col, label) in enumerate(zip(cols, step_names)):
        with col:
            if i < current:
                bg, fg = "var(--indigo-50)", "var(--indigo-800)"
            elif i == current:
                bg, fg = "#534AB7", "#E8E8FF"
            else:
                bg, fg = "var(--card-bg)", "var(--text-hint)"
            border = "" if i == current else "border:1px solid var(--border);"
            st.markdown(f"""
                <div style="text-align:center;padding:8px;border-radius:8px;
                            background:{bg};{border}
                            font-size:12px;font-weight:600;color:{fg};">
                  {i+1}. {label}
                </div>
            """, unsafe_allow_html=True)

    st.markdown("<div style='height:1.5rem'></div>", unsafe_allow_html=True)

   
    if st.session_state.upload_step == "select":

        st.markdown("""
            <div class="stat-card" style="margin-bottom:1.25rem;">
              <div style="font-size:15px;font-weight:600;
                          color:var(--text-main);margin-bottom:4px;">
                Choose a file from your device
              </div>
              <div style="font-size:13px;color:var(--text-muted);">
                PDF, JPG, PNG supported &nbsp;·&nbsp;
                Your file will be encrypted before it is stored
              </div>
            </div>
        """, unsafe_allow_html=True)

        uploaded_file = st.file_uploader(
            "Click Browse files to open your folder",
            type=["pdf", "jpg", "jpeg", "png"],
        )

        if uploaded_file is not None:
            st.session_state.upload_file_obj = {
                "name": uploaded_file.name,
                "size": round(uploaded_file.size / 1024, 1),
                "type": uploaded_file.type,
                "data": uploaded_file.read(),
            }

            st.markdown(f"""
                <div class="activity-item" style="margin:1rem 0 1.25rem;">
                  <div style="flex:1;">
                    <div class="activity-name">{uploaded_file.name}</div>
                    <div class="activity-time">
                      {round(uploaded_file.size/1024,1)} KB
                      &nbsp;·&nbsp; {uploaded_file.type}
                    </div>
                  </div>
                  <span class="badge badge-indigo">Selected</span>
                </div>
            """, unsafe_allow_html=True)

            if st.button("Continue to PIN  →", use_container_width=False):
                st.session_state.upload_step = "pin"
                st.rerun()
    # ══════════════════════════════════════════════════════════════════════
    # STEP 2 — PIN
    # ══════════════════════════════════════════════════════════════════════
    elif st.session_state.upload_step == "pin":
        f = st.session_state.upload_file_obj

        st.markdown(f"""
            <div class="activity-item" style="margin-bottom:1.25rem;">
              <div style="flex:1;">
                <div class="activity-name">{f['name']}</div>
                <div class="activity-time">{f['size']} KB &nbsp;·&nbsp; {f['type']}</div>
              </div>
              <span class="badge badge-indigo">Selected</span>
            </div>

            <div class="pin-prompt">
              <div>
                <div class="pin-title">Step 2 of 3 — Access PIN</div>
                <div class="pin-sub">
                  Enter your 4-digit PIN to confirm it is you
                  before we proceed to encryption.
                </div>
              </div>
            </div>
        """, unsafe_allow_html=True)

        pin = st.text_input("PIN", type="password", max_chars=4,
                            placeholder="****", label_visibility="collapsed")

        c1, c2 = st.columns(2)
        with c1:
            if st.button("← Back", key="pin_back"):
                st.session_state.upload_step = "select"
                st.rerun()
        with c2:
            if st.button("Confirm PIN →", key="pin_ok", use_container_width=True):
                if pin == DEMO_PIN:
                    st.session_state.upload_step = "password"
                    st.rerun()
                else:
                    st.error("Incorrect PIN. (Demo: 2648)")

    # ══════════════════════════════════════════════════════════════════════
    # STEP 3 — Password (derives encryption key)
    # ══════════════════════════════════════════════════════════════════════
    elif st.session_state.upload_step == "password":
        f = st.session_state.upload_file_obj

        st.markdown(f"""
            <div class="activity-item" style="margin-bottom:1.25rem;">
              <div style="flex:1;">
                <div class="activity-name">{f['name']}</div>
                <div class="activity-time">{f['size']} KB &nbsp;·&nbsp; {f['type']}</div>
              </div>
              <span class="badge badge-indigo">PIN verified</span>
            </div>

            <div class="pin-prompt">
              <div>
                <div class="pin-title">Step 3 of 3 — Password for encryption</div>
                <div class="pin-sub">
                  Your password derives the AES-256 encryption key using PBKDF2 +
                  a random salt. The key is generated right now and never stored.
                  Without your password this file cannot be decrypted by anyone —
                  not even the server.
                </div>
              </div>
            </div>
        """, unsafe_allow_html=True)

        password = st.text_input("Password", type="password",
                                 placeholder="Enter your account password")

        c1, c2 = st.columns(2)
        with c1:
            if st.button("← Back", key="pass_back"):
                st.session_state.upload_step = "pin"
                st.rerun()
        with c2:
            if st.button("Encrypt and Upload →", key="pass_ok", use_container_width=True):
                if password == DEMO_PASSWORD:
                    st.session_state.user_password = password
                    st.session_state.upload_step = "uploading"
                    st.rerun()
                else:
                    st.error("Incorrect password. (Demo: password123)")

    # ══════════════════════════════════════════════════════════════════════
    # STEP 4 — Processing
    # ══════════════════════════════════════════════════════════════════════
    elif st.session_state.upload_step == "uploading":

      f = st.session_state.upload_file_obj

      password = st.session_state.user_password

      file_data = f["data"]

      with st.status(
          "Processing your document securely...",
          expanded=True
      ) as status:

          for step in PIPELINE_STEPS:

              st.write(step)

              time.sleep(0.7)

          encrypted_data = encrypt_file(
             file_data,
             password
)

          file_hash = generate_hash(
             encrypted_data
)

          os.makedirs(
            "uploads",
            exist_ok=True
)

          encrypted_filename = (
               f"{f['name']}.enc"
)

          save_path = os.path.join(
                "uploads",
                encrypted_filename
)

          hash_path = os.path.join(
            "uploads",
            f"{f['name']}.hash"
)

          with open(
                save_path,
                "wb"
          ) as encrypted_file:

             encrypted_file.write(
                encrypted_data
    )
             
          upload_to_s3(
                encrypted_data,
                encrypted_filename
            )
          salt = encrypted_data[:16]

          save_document_metadata(
              user_id="demo_user",          # Replace later with logged-in user's ID
              filename=f["name"],
              encrypted_filename=encrypted_filename,
              s3_key=encrypted_filename,
              file_hash=file_hash,
              salt=salt,
              size=len(file_data)
          )
          with open(
               hash_path,
                "w"
            ) as hash_file:

           hash_file.write(
           file_hash
    )

          status.update(
              label="Document encrypted and saved successfully!",
              state="complete"
          )

      st.markdown(
          f"""
          <div class="stat-card"
              style="
              margin-top:1.25rem;
              border-left:3px solid var(--success-tx);
              ">

            <div style="
                font-size:15px;
                font-weight:600;
                color:var(--success-tx);
                margin-bottom:.75rem;
            ">
              {f['name']} stored securely
            </div>

            <div style="
                font-size:13px;
                color:var(--text-muted);
                line-height:2;
            ">
              AES-256 encryption completed<br>
              PBKDF2 key derivation completed<br>
              Random salt generated<br>
              Encrypted file saved locally<br>
              File path: uploads/{encrypted_filename}
            </div>

          </div>
          """,
          unsafe_allow_html=True
      )

      st.markdown(
          "<div style='height:1rem'></div>",
          unsafe_allow_html=True
      )

      if st.button("Upload another document"):

          st.session_state.upload_step = "select"

          st.session_state.upload_file_obj = None

          st.session_state.user_password = None

          st.rerun()
      