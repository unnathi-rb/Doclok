import streamlit as st
import os
import uuid

from utils.hash_utils import generate_hash
from utils.encryption import encrypt_file, encrypt_filename
from utils.s3_utils import upload_to_s3
from utils.mongodb import (
    save_document_metadata,
    verify_pin,
    verify_password
)
from utils.security_utils import (
    is_locked_out,
    register_failed_attempt,
    reset_attempts
)


PIPELINE_STEPS = [
    "Step 1 — Encrypting your file (AES-256)...",
    "Step 2 — Creating security fingerprint (SHA-256)...",
    "Step 3 — Saving securely to cloud (AWS S3)...",
]


def render_upload():

    # ==========================================================
    # SESSION STATE
    # ==========================================================

    if "upload_step" not in st.session_state:
        st.session_state.upload_step = "select"

    if "upload_file_obj" not in st.session_state:
        st.session_state.upload_file_obj = None

    if "user_password" not in st.session_state:
        st.session_state.user_password = None

    if "uploader_key" not in st.session_state:
        st.session_state.uploader_key = 0


    # ==========================================================
    # USER DETAILS
    # ==========================================================

    user_email = st.session_state.user_email
    user_name = st.session_state.get("user_name", "User")

    initials = "".join(
        part[0].upper()
        for part in user_name.split()[:2]
    ) or "U"


    # ==========================================================
    # TOP BAR
    # IMPORTANT: SINGLE-LINE HTML
    # ==========================================================

    topbar_html = (
        f'<div class="topbar">'
        f'<div class="topbar-title">Upload document</div>'
        f'<div class="avatar-sm">{initials}</div>'
        f'</div>'
    )

    st.markdown(
        topbar_html,
        unsafe_allow_html=True
    )


    # ==========================================================
    # STEP TRACKER
    # ==========================================================

    step_map = {
        "select": 0,
        "pin": 1,
        "password": 2,
        "uploading": 3,
        "done": 3,
    }

    step_names = [
        "Select file",
        "Enter PIN",
        "Enter password",
        "Done"
    ]

    current = step_map.get(
        st.session_state.upload_step,
        0
    )

    cols = st.columns(4)

    for i, (col, label) in enumerate(
        zip(cols, step_names)
    ):

        with col:

            if i < current:
                bg = "var(--indigo-50)"
                fg = "var(--indigo-800)"
                border = "1px solid var(--border)"

            elif i == current:
                bg = "#534AB7"
                fg = "#E8E8FF"
                border = "none"

            else:
                bg = "var(--card-bg)"
                fg = "var(--text-hint)"
                border = "1px solid var(--border)"

            step_html = (
                f'<div style="'
                f'text-align:center;'
                f'padding:8px;'
                f'border-radius:8px;'
                f'background:{bg};'
                f'border:{border};'
                f'font-size:12px;'
                f'font-weight:600;'
                f'color:{fg};'
                f'">'
                f'{i + 1}. {label}'
                f'</div>'
            )

            st.markdown(
                step_html,
                unsafe_allow_html=True
            )


    st.markdown(
        "<div style='height:1.5rem'></div>",
        unsafe_allow_html=True
    )


    # ==========================================================
    # STEP 1 — SELECT FILE
    # ==========================================================

    if st.session_state.upload_step == "select":

        st.caption(
            "Your file will be encrypted before it is stored"
        )

        uploaded_file = st.file_uploader(
            "Upload a document",
            type=["pdf", "jpg", "jpeg", "png"],
            label_visibility="collapsed",
            key=f"file_uploader_{st.session_state.uploader_key}"
        )


        if uploaded_file is not None:

            st.session_state.upload_file_obj = {
                "name": uploaded_file.name,
                "size": round(
                    uploaded_file.size / 1024,
                    1
                ),
                "type": uploaded_file.type,
                "data": uploaded_file.getvalue(),
            }


            file_html = (
                f'<div class="activity-item" '
                f'style="margin:1rem 0 1.25rem;">'
                f'<div style="flex:1;">'
                f'<div class="activity-name">'
                f'{uploaded_file.name}'
                f'</div>'
                f'<div class="activity-time">'
                f'{round(uploaded_file.size / 1024, 1)} KB'
                f'&nbsp;·&nbsp;'
                f'{uploaded_file.type}'
                f'</div>'
                f'</div>'
                f'<span class="badge badge-indigo">'
                f'Selected'
                f'</span>'
                f'</div>'
            )

            st.markdown(
                file_html,
                unsafe_allow_html=True
            )


            if st.button("Continue to PIN →"):

                st.session_state.upload_step = "pin"

                st.rerun()


    # ==========================================================
    # STEP 2 — PIN
    # ==========================================================

    elif st.session_state.upload_step == "pin":

        f = st.session_state.upload_file_obj


        selected_file_html = (
            f'<div class="activity-item" '
            f'style="margin-bottom:1.25rem;">'
            f'<div style="flex:1;">'
            f'<div class="activity-name">'
            f'{f["name"]}'
            f'</div>'
            f'<div class="activity-time">'
            f'{f["size"]} KB'
            f'&nbsp;·&nbsp;'
            f'{f["type"]}'
            f'</div>'
            f'</div>'
            f'<span class="badge badge-indigo">'
            f'Selected'
            f'</span>'
            f'</div>'
            f'<div class="pin-prompt">'
            f'<div>'
            f'<div class="pin-title">'
            f'Step 2 of 3 — Access PIN'
            f'</div>'
            f'<div class="pin-sub">'
            f'Enter your 4-digit PIN to confirm it is you '
            f'before we proceed to encryption.'
            f'</div>'
            f'</div>'
            f'</div>'
        )

        st.markdown(
            selected_file_html,
            unsafe_allow_html=True
        )


        pin = st.text_input(
            "PIN",
            type="password",
            max_chars=4,
            placeholder="****",
            label_visibility="collapsed"
        )


        locked, remaining = is_locked_out(
            "upload_pin"
        )


        if locked:

            st.error(
                f"Too many incorrect PIN attempts. "
                f"Try again in {remaining}s."
            )


        c1, c2 = st.columns(2)


        with c1:

            if st.button(
                "← Back",
                key="pin_back"
            ):

                st.session_state.upload_step = "select"

                st.rerun()


        with c2:

            if st.button(
                "Confirm PIN →",
                key="pin_ok",
                use_container_width=True,
                disabled=locked
            ):

                if verify_pin(
                    user_email,
                    pin
                ):

                    reset_attempts(
                        "upload_pin"
                    )

                    st.session_state.upload_step = "password"

                    st.rerun()

                else:

                    register_failed_attempt(
                        "upload_pin"
                    )

                    st.error(
                        "Incorrect PIN."
                    )


    # ==========================================================
    # STEP 3 — PASSWORD
    # ==========================================================

    elif st.session_state.upload_step == "password":

        f = st.session_state.upload_file_obj


        password_html = (
            f'<div class="activity-item" '
            f'style="margin-bottom:1.25rem;">'
            f'<div style="flex:1;">'
            f'<div class="activity-name">'
            f'{f["name"]}'
            f'</div>'
            f'<div class="activity-time">'
            f'{f["size"]} KB'
            f'&nbsp;·&nbsp;'
            f'{f["type"]}'
            f'</div>'
            f'</div>'
            f'<span class="badge badge-indigo">'
            f'PIN verified'
            f'</span>'
            f'</div>'
            f'<div class="pin-prompt">'
            f'<div>'
            f'<div class="pin-title">'
            f'Step 3 of 3 — Password for encryption'
            f'</div>'
            f'<div class="pin-sub">'
            f'Your password derives the AES-256 encryption key '
            f'using PBKDF2 and a random salt. '
            f'The key is generated now and never stored. '
            f'Without your password this file cannot be decrypted.'
            f'</div>'
            f'</div>'
            f'</div>'
        )

        st.markdown(
            password_html,
            unsafe_allow_html=True
        )


        password = st.text_input(
            "Password",
            type="password",
            placeholder="Enter your account password"
        )


        c1, c2 = st.columns(2)


        with c1:

            if st.button(
                "← Back",
                key="pass_back"
            ):

                st.session_state.upload_step = "pin"

                st.rerun()


        with c2:

            if st.button(
                "Encrypt and Upload →",
                key="pass_ok",
                use_container_width=True
            ):

                if verify_password(
                    user_email,
                    password
                ):

                    st.session_state.user_password = password

                    st.session_state.upload_step = "uploading"

                    st.rerun()

                else:

                    st.error(
                        "Incorrect password."
                    )


    # ==========================================================
    # STEP 4 — ACTUAL UPLOAD
    # ==========================================================

    elif st.session_state.upload_step == "uploading":

        f = st.session_state.upload_file_obj

        password = st.session_state.user_password

        file_data = f["data"]


        with st.status(
            "Processing your document securely...",
            expanded=True
        ) as status:


            # Encrypt file
            st.write(
                PIPELINE_STEPS[0]
            )

            encrypted_data = encrypt_file(
                file_data,
                password
            )


            # Encrypt original filename
            encrypted_name = encrypt_file(
                f["name"].encode(),
                password
            )


            # Encrypt display filename
            display_name_enc = encrypt_filename(
                f["name"]
            )


            # Generate SHA-256 hash
            st.write(
                PIPELINE_STEPS[1]
            )

            file_hash = generate_hash(
                encrypted_data
            )


            # Ensure uploads directory exists
            os.makedirs(
                "uploads",
                exist_ok=True
            )


            # Generate unique filename
            encrypted_filename = (
                f"{user_email}_"
                f"{uuid.uuid4().hex}.enc"
            )


            save_path = os.path.join(
                "uploads",
                encrypted_filename
            )


            hash_path = os.path.join(
                "uploads",
                f"{encrypted_filename}.hash"
            )


            # Save encrypted file locally
            with open(
                save_path,
                "wb"
            ) as encrypted_file:

                encrypted_file.write(
                    encrypted_data
                )


            # Upload encrypted file to S3
            st.write(
                PIPELINE_STEPS[2]
            )

            upload_to_s3(
                encrypted_data,
                encrypted_filename
            )


            # Extract salt
            salt = encrypted_data[:16]


            # Save metadata in MongoDB
            save_document_metadata(
                user_id=user_email,
                encrypted_name=encrypted_name,
                display_name_enc=display_name_enc,
                encrypted_filename=encrypted_filename,
                s3_key=encrypted_filename,
                file_hash=file_hash,
                salt=salt,
                size=len(file_data)
            )


            # Save hash locally
            with open(
                hash_path,
                "w"
            ) as hash_file:

                hash_file.write(
                    file_hash
                )


            status.update(
                label=(
                    "Document encrypted and "
                    "saved successfully!"
                ),
                state="complete"
            )


        # IMPORTANT:
        # Upload is complete.
        # Change state so it NEVER uploads again
        # when the user revisits this page.

        st.session_state.upload_step = "done"

        st.rerun()


    # ==========================================================
    # STEP 5 — DONE
    # ==========================================================

    elif st.session_state.upload_step == "done":

        f = st.session_state.upload_file_obj


        success_html = (
            f'<div class="stat-card" '
            f'style="margin-top:1.25rem;'
            f'border-left:3px solid var(--success-tx);">'
            f'<div style="'
            f'font-size:15px;'
            f'font-weight:600;'
            f'color:var(--success-tx);'
            f'margin-bottom:.75rem;'
            f'">'
            f'{f["name"]} stored securely'
            f'</div>'
            f'<div style="'
            f'font-size:13px;'
            f'color:var(--text-muted);'
            f'line-height:2;'
            f'">'
            f'AES-256 encryption completed<br>'
            f'PBKDF2 key derivation completed<br>'
            f'Random salt generated<br>'
            f'Filename encrypted<br>'
            f'Encrypted file saved locally<br>'
            f'Securely uploaded to AWS S3'
            f'</div>'
            f'</div>'
        )


        st.markdown(
            success_html,
            unsafe_allow_html=True
        )


        st.markdown(
            "<div style='height:1rem'></div>",
            unsafe_allow_html=True
        )


        if st.button(
            "Upload another document"
        ):

            st.session_state.upload_step = "select"

            st.session_state.upload_file_obj = None

            st.session_state.user_password = None

            # Reset Streamlit file uploader
            st.session_state.uploader_key += 1

            st.rerun()