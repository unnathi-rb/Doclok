# DocLok: Secure Document Vault

> A personal document vault that encrypts your files **before** they reach the cloud.

DocLok protects sensitive documents like IDs, certificates, medical and bank records. It secures the **content itself** with password-derived encryption, three-step login, and tamper detection on every access.

---

## Features

- **Login:** password → email OTP → PIN, JWT sessions, lockout after repeated wrong attempts
- **Recovery:** forgot PIN, password recovery with a one-time recovery key
- **Documents:** upload (max 25 MB), view, download, delete, folders
- **Security badge:** Encrypted / Verified / Tampered on every file
- **Dashboard:** document count, recent activity, storage usage
- **Apps:** web and Android, light/dark themes

---

## How It Works

**Upload**
```text
File + PIN + password → random salt → PBKDF2-SHA256 key (100,000 iterations)
→ Fernet encryption → SHA-256 hash → encrypted file to S3 (random name), metadata to MongoDB
```

**View / download**
```text
PIN + password → fetch from S3 → recompute SHA-256
→ mismatch: flagged "Tampered", not opened
→ match: decrypt and return
```

**Key points**
- The encryption key is rebuilt from the password each time and **never stored**. A new salt per file means the same password gives a different key every time.
- S3 holds only encrypted files under random names. Real file names are stored encrypted in MongoDB.
- **Recovery key:** shown once at signup. It can restore a forgotten password. If both are lost, files can't be decrypted. This is by design.
- **Login:** OTP is valid 5 minutes, JWT 12 hours, web app logs out after 15 minutes of inactivity.

> **Note:** encryption runs on the **server**, so it briefly handles the password and plain file. DocLok is a student project and hasn't had an independent security audit. Don't use it for real sensitive data without reviewing the code.

---

## Architecture

```text
┌──────────────┐                        ┌─────────────────────────┐
│ Streamlit web│── imports directly ──► │ utils/ (encryption,     │
└──────────────┘                        │ hashing, S3, MongoDB,   │
┌──────────────┐   HTTPS + JWT          │ OTP, recovery)          │
│ Flutter app  │──► FastAPI (api/) ───► │                         │
└──────────────┘                        └───────┬─────────┬───────┘
                                           MongoDB      AWS S3     (+ Resend for OTP)
```

Both apps share the same core logic, so a file uploaded on the web opens on the phone and vice versa.

**Tech stack:** Streamlit · Flutter/Dart (Provider) · FastAPI · PyJWT · MongoDB · AWS S3 (boto3) · `cryptography` (Fernet, PBKDF2) · Resend · Render

---

## Project Structure

```text
Doclok/
├── app.py          # Streamlit entry point
├── pages/          # Streamlit screens (login, home, upload, documents, security, profile)
├── components/     # Streamlit sidebar
├── api/            # FastAPI backend: main.py (routes), auth.py (JWT), lockout.py
├── utils/          # Shared logic: encryption, hashing, S3, MongoDB, OTP, recovery
├── mobile/         # Flutter app
│   └── lib/        #   config, services, models, screens, widgets, theme
├── docs/screenshots/
├── requirements.txt
└── .env.example
```

---

## Setup

**Prerequisites:** Python 3.10+, MongoDB, an AWS S3 bucket with an IAM user, a [Resend](https://resend.com) API key, Flutter 3.3+ (mobile only)

**Install**

```bash
git clone https://github.com/unnathi-rb/Doclok.git
cd Doclok
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**Configure**

```bash
cp .env.example .env
```

| Variable | Purpose |
|---|---|
| `MONGODB_URI` | MongoDB connection string (database: `doclok`) |
| `AWS_ACCESS_KEY` / `AWS_SECRET_KEY` | IAM keys for the S3 bucket |
| `APP_MASTER_KEY` | Encrypts file names in MongoDB. Any long random string. **If lost, existing file names can't be decrypted.** |
| `JWT_SECRET_KEY` | Signs JWT access tokens |
| `RESEND_API_KEY` | Sends OTP emails |
| `SMTP_EMAIL` | Sender email setting (optional) |

Generate a secret: `python -c "import secrets; print(secrets.token_urlsafe(48))"`  
**Never commit `.env`.**

**Run**

```bash
streamlit run app.py                 # web app → http://localhost:8501
uvicorn api.main:app --reload        # API → http://localhost:8000 (docs at /docs)
```

---

## Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

Set `baseUrl` in `mobile/lib/config/api_config.dart`:

| Running on | `baseUrl` |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| Physical phone (same Wi-Fi) | `http://<your-LAN-IP>:8000` |
| Deployed backend | your `https://` URL |

Build an APK: `flutter build apk --release`

**Code layout (`mobile/lib/`):** `config/` backend URL · `services/` API calls and secure token storage · `models/` data classes · `screens/` auth, home, documents, security, profile, legal · `widgets/` reusable UI · `theme/` colors and light/dark mode

> The first request to the Render-hosted API can be slow if the free instance was asleep.

---

## API Overview

All routes except `/health` and `/auth/*` need `Authorization: Bearer <token>`. Full list at `/docs`.

| Area | Endpoints |
|---|---|
| Auth | `/auth/signup`, `/auth/login/password`, `/auth/login/resend-otp`, `/auth/login/verify-otp`, `/auth/login/verify-pin`, `/auth/forgot-pin`, `/auth/recover-password` |
| Documents | `/documents/upload`, `/documents`, `/documents/{id}/verify-pin`, `/documents/{id}/decrypt`, `DELETE /documents/{id}` |
| Folders | `/folders` (create, list), `DELETE /folders/{name}` |
| Account | `/security/update-pin`, `/profile` (get, update), `DELETE /account`, `/health` |

---

## Limitations and Future Scope

**Limitations:** needs internet · small delay from encryption and hash checks · files processed in memory (25 MB cap)

**Future:** iOS/macOS release · end-to-end encryption · role-based access, secure sharing and audit logs for organizations · paid storage tier
