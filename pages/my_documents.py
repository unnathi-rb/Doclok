import streamlit as st

import os
from utils.encryption import decrypt_file
from utils.hash_utils import verify_sha256
from utils.mongodb import get_all_documents
from utils.s3_utils import (
    download_from_s3,
    delete_from_s3,
)

from utils.mongodb import (
    get_all_documents,
    delete_document,
    verify_pin,
    verify_password,
)
from utils.security_utils import is_locked_out, register_failed_attempt, reset_attempts


def render_my_documents():
    if "selected_doc"       not in st.session_state: st.session_state.selected_doc       = None
    if "doc_pin_ok"         not in st.session_state: st.session_state.doc_pin_ok         = False
    if "doc_password_ok"    not in st.session_state: st.session_state.doc_password_ok    = False
    if "doc_password_val"   not in st.session_state: st.session_state.doc_password_val   = ""

    user_email = st.session_state.user_email
    user_name  = st.session_state.get("user_name", "User")
    initials   = "".join([p[0].upper() for p in user_name.split()[:2]]) or "U"

    st.markdown(f"""
    <div class="topbar">
        <div class="topbar-title">My Documents</div>
        <div class="avatar-sm">{initials}</div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("""
        <div style="background:var(--indigo-50);border:1px solid var(--border);
                    border-radius:10px;padding:10px 16px;margin-bottom:1.5rem;
                    font-size:13px;color:var(--indigo-800);">
          Viewing or downloading a file requires your PIN and your password.
          Your password is used to decrypt the file (and its filename) — it is never stored anywhere.
          Because filenames are encrypted, they aren't visible until you unlock a document.
        </div>
    """, unsafe_allow_html=True)


    documents = get_all_documents(user_email)

    docs = []

    for document in documents:

        docs.append({

            "id": document["s3_key"],

            "encrypted_name": document["encrypted_name"],

            "category": "Document",

            "status": document["status"],

            "size": f"{round(document['size']/1024,1)} KB",

            "date": document["uploaded_at"].strftime("%d %b %Y"),

            "hash": document["hash"],

            "has_sensitive_data": document.get("has_sensitive_data", False)

        })

    st.markdown("<div style='height:4px'></div>", unsafe_allow_html=True)
    for doc in docs:
        col_main, col_view, col_dl, col_del = st.columns([5, 1, 1, 1])

        with col_main:
            sensitive_badge = (
                '&nbsp;<span class="badge" style="font-size:11px;background:#FDECEC;color:#B3261E">⚠ Sensitive info</span>'
                if doc.get("has_sensitive_data") else ""
            )
            display_name = st.session_state.get(f"decrypted_name_{doc['id']}", "🔒 Encrypted document")
            st.markdown(f"""
                <div class="doc-row">
                  <div style="flex:1;">
                    <div class="doc-name">{display_name}
                      &nbsp;<span class="badge badge-indigo" style="font-size:11px">{doc["status"]}</span>{sensitive_badge}
                    </div>
                    <div class="doc-meta">
                      {doc['category']} &nbsp;·&nbsp; {doc['size']} &nbsp;·&nbsp; {doc['date']}
                    </div>
                  </div>
                </div>
            """, unsafe_allow_html=True)
        with col_view:

            if st.button(
                "View",
                key=f"view_{doc['id']}"
            ):

                st.session_state.selected_doc = doc["id"]

                st.session_state.doc_pin_ok = False

                st.session_state.doc_password_ok = False

                st.rerun()
            
        with col_dl:

            if st.button(
                "Download",
                key=f"dl_{doc['id']}"
            ):

                # Downloading needs the same PIN + password decryption gate as View
                st.session_state.selected_doc = doc["id"]

                st.session_state.doc_pin_ok = False

                st.session_state.doc_password_ok = False

                st.rerun()
        with col_del:

            if st.button(
                "Delete",
                key=f"del_{doc['id']}"
            ):

                delete_from_s3(
                    doc["id"]
                )

                delete_document(
                    doc["id"]
                )

                local_file = os.path.join(
                    "uploads",
                    doc["id"]
                )

                if os.path.exists(local_file):
                    os.remove(local_file)

                st.success("Document deleted successfully.")

                st.rerun()

        # ── Two-step access gate ──────────────────────────────────────────
        if st.session_state.selected_doc == doc["id"]:

            # ── STEP 1: PIN (authorization) ───────────────────────────────
            if not st.session_state.doc_pin_ok:
                st.markdown(f"""
                    <div style="background:var(--card-bg);border:1px solid var(--border);
                                border-radius:10px;padding:1rem 1.3rem;margin-bottom:8px;">
                      <div style="font-size:14px;font-weight:600;
                                  color:var(--text-main);margin-bottom:4px;">
                        Step 1 of 2 — Enter your access PIN
                      </div>
                      <div style="font-size:13px;color:var(--text-muted);">
                        Confirm it is you before we proceed to decryption.
                      </div>
                    </div>
                """, unsafe_allow_html=True)

                p1, p2 = st.columns([1, 2])
                with p1:
                    pin_val = st.text_input(
                        "Access PIN", type="password", max_chars=4,
                        placeholder="****", key=f"pin_{doc['id']}"
                    )
                with p2:
                    st.markdown("<div style='height:28px'></div>", unsafe_allow_html=True)
                    locked, remaining = is_locked_out(f"doc_pin_{doc['id']}")
                    if locked:
                        st.error(f"Too many attempts. Try again in {remaining}s.")
                    elif st.button("Confirm PIN", key=f"pin_btn_{doc['id']}"):
                        if verify_pin(user_email, pin_val):
                            reset_attempts(f"doc_pin_{doc['id']}")
                            st.session_state.doc_pin_ok = True
                            st.rerun()
                        else:
                            register_failed_attempt(f"doc_pin_{doc['id']}")
                            st.error("Incorrect PIN.")

            # ── STEP 2: Password (decryption key) ─────────────────────────
            elif not st.session_state.doc_password_ok:
                st.markdown(f"""
                    <div style="background:var(--card-bg);border:1px solid var(--border);
                                border-radius:10px;padding:1rem 1.3rem;margin-bottom:8px;">
                      <div style="font-size:14px;font-weight:600;
                                  color:var(--text-main);margin-bottom:4px;">
                        Step 2 of 2 — Enter your password to decrypt
                      </div>
                      <div style="font-size:13px;color:var(--text-muted);">
                        Your encryption key is derived from your password using PBKDF2.
                        It is used right now to decrypt this file (and its filename) and is never stored.
                      </div>
                    </div>
                """, unsafe_allow_html=True)

                p1, p2 = st.columns([1, 2])
                with p1:
                    pass_val = st.text_input(
                        "Your password", type="password",
                        placeholder="Enter your password", key=f"pass_{doc['id']}"
                    )
                with p2:
                    st.markdown("<div style='height:28px'></div>", unsafe_allow_html=True)
                    if st.button("Decrypt and View", key=f"pass_btn_{doc['id']}"):
                        if verify_password(user_email, pass_val):
                            try:
                                decrypted_name = decrypt_file(doc["encrypted_name"], pass_val).decode()
                                st.session_state[f"decrypted_name_{doc['id']}"] = decrypted_name
                                st.session_state.doc_password_ok = True
                                st.session_state.doc_password_val = pass_val
                                st.rerun()
                            except Exception:
                                st.error("Could not decrypt this document's filename with that password.")
                        else:
                            st.error("Incorrect password. Cannot decrypt file.")

            # ── Both passed — show decrypted file details ──────────────────
            
            else:

              # Download encrypted file from AWS S3
                encrypted_data = download_from_s3(
                    doc["id"]
                )

                # ── Tamper detection: recompute hash and compare to what was stored at upload ──
                is_intact = verify_sha256(encrypted_data, doc["hash"])

                if not is_intact:
                    st.error(
                        "⚠ Tampered — this file's integrity check failed. "
                        "The stored fingerprint no longer matches the file in cloud storage, "
                        "so it will not be decrypted."
                    )
                    if st.button("Close", key=f"close_tampered_{doc['id']}"):
                        st.session_state.selected_doc = None
                        st.session_state.doc_pin_ok = False
                        st.session_state.doc_password_ok = False
                        st.session_state.doc_password_val = ""
                        st.rerun()

                else:

                    # Decrypt it using the password just entered
                    decrypted_data = decrypt_file(
                        encrypted_data,
                        st.session_state.doc_password_val
                    )

                    real_name = st.session_state.get(f"decrypted_name_{doc['id']}", "document")

                    file_extension = real_name.rsplit(".", 1)[-1].lower() if "." in real_name else ""

                    st.success("✅ Integrity verified — file matches its stored fingerprint.")

                    st.download_button(
                        "⬇ Download decrypted file",
                        data=decrypted_data,
                        file_name=real_name,
                        key=f"download_{doc['id']}"
                    )

                    if file_extension in ["jpg", "jpeg", "png"]:

                        st.image(
                            decrypted_data,
                            use_container_width=True
                        )

                    elif file_extension == "pdf":

                        import base64

                        pdf_base64 = base64.b64encode(
                            decrypted_data
                        ).decode()

                        st.markdown(
                            f"""
                            <iframe
                            src="data:application/pdf;base64,{pdf_base64}"
                            width="100%"
                            height="700">
                            </iframe>
                            """,
                            unsafe_allow_html=True
                        )

                    elif file_extension == "txt":

                        st.text(
                            decrypted_data.decode(
                                errors="ignore"
                            )
                        )

                    else:

                        st.download_button(
                            "Download File",
                            data=decrypted_data,
                            file_name=real_name
                        )

                    if st.button(
                        "Close",
                        key=f"close_{doc['id']}"
                    ):

                        st.session_state.selected_doc = None
                        st.session_state.doc_pin_ok = False
                        st.session_state.doc_password_ok = False
                        st.session_state.doc_password_val = ""
                        st.session_state.pop(f"decrypted_name_{doc['id']}", None)
                        st.rerun()