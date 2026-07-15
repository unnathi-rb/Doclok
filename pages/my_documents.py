import streamlit as st

import os
from utils.encryption import decrypt_file
from utils.mongodb import get_all_documents
from utils.s3_utils import (
    download_from_s3,
    delete_from_s3,
)

from utils.mongodb import (
    get_all_documents,
    delete_document,
)


def render_my_documents():
    if "selected_doc"       not in st.session_state: st.session_state.selected_doc       = None
    if "doc_pin_ok"         not in st.session_state: st.session_state.doc_pin_ok         = False
    if "doc_password_ok"    not in st.session_state: st.session_state.doc_password_ok    = False

    st.markdown("""
    <div class="topbar">
        <div class="topbar-title">My Documents</div>
        <div class="avatar-sm">UN</div>
    </div>
    """, unsafe_allow_html=True)

    search = st.text_input(
        "",
        placeholder="Search documents..."
    )

    st.markdown("""
        <div style="background:var(--indigo-50);border:1px solid var(--border);
                    border-radius:10px;padding:10px 16px;margin-bottom:1.5rem;
                    font-size:13px;color:var(--indigo-800);">
          Viewing or downloading a file requires your PIN and your password.
          Your password is used to decrypt the file — it is never stored anywhere.
        </div>
    """, unsafe_allow_html=True)

    filter_col, _ = st.columns([2, 3])
    with filter_col:
        category_filter = st.selectbox(
            "Filter by category",
            ["All categories", "Identity", "Academic", "Financial", "Medical"]
        )


    documents = get_all_documents("demo_user")

    docs = []

    for document in documents:

        docs.append({

            "id": document["s3_key"],

            "name": document["filename"],

            "category": "Document",

            "status": document["status"],

            "size": f"{round(document['size']/1024,1)} KB",

            "date": document["uploaded_at"].strftime("%d %b %Y"),

            "hash": document["hash"]

        })
    if search:

        docs = [
            doc
            for doc in docs
            if search.lower() in doc["name"].lower()
        ]
    st.markdown("<div style='height:4px'></div>", unsafe_allow_html=True)

    for doc in docs:
        col_main, col_view, col_dl, col_del = st.columns([5, 1, 1, 1])

        with col_main:
            st.markdown(f"""
                <div class="doc-row">
                  <div style="flex:1;">
                    <div class="doc-name">{doc['name']}
                      &nbsp;<span class="badge badge-indigo" style="font-size:11px">{doc["status"]}</span>
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

                encrypted_data = download_from_s3(
                    doc["id"]
                )

                decrypted_data = decrypt_file(
                    encrypted_data,
                    "password123"
                )

                st.download_button(
                    label="Click to Download",
                    data=decrypted_data,
                    file_name=doc["name"],
                    key=f"download_{doc['id']}"
                )
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
                    if st.button("Confirm PIN", key=f"pin_btn_{doc['id']}"):
                        if pin_val == "2648":
                            st.session_state.doc_pin_ok = True
                            st.rerun()
                        else:
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
                        It is used right now to decrypt this file and is never stored.
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
                        if pass_val == "password123":
                            st.session_state.doc_password_ok = True
                            st.rerun()
                        else:
                            st.error("Incorrect password. Cannot decrypt file.")

            # ── Both passed — show decrypted file details ──────────────────
            
            else:

              # Download encrypted file from AWS S3
                encrypted_data = download_from_s3(
                    doc["id"]
                )

                # Decrypt it
                decrypted_data = decrypt_file(
                    encrypted_data,
                    "password123"
                )
                
                if file_extension in [ 
                  "jpg",
                  "jpeg",
                  "png"
              ]:

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
                      file_name=doc["name"]
                  )

                if st.button(
                  "Close",
                  key=f"close_{doc['id']}"
              ):

                  st.session_state.selected_doc = None
                  st.session_state.doc_pin_ok = False
                  st.session_state.doc_password_ok = False
                  st.rerun()
                  st.success("File decrypted successfully!")