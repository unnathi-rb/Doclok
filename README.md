# DocLok: Secure Cloud Document Vault

*Web app (Streamlit) + REST API (FastAPI) + Android app (Flutter)*

---

## 1. Problem Statement

People now store important documents online: ID proofs, certificates, medical records, bank papers, property papers. It's convenient for job applications, loans and healthcare, but most users don't know how safely their files are handled after upload. A leak can lead to identity theft, phishing or financial fraud.

There is a clear need for a document vault that is not only easy to use, but protects the data itself and gives users real control over it.

## 2. Target Audience

Students, job seekers, working professionals and families who regularly share documents for banking, healthcare or job verification and want their personal information kept private.

## 3. What Makes DocLok Different

Most platforms focus on storing and sharing. DocLok focuses on protecting the content at every step.

- **Encrypted before upload.** Only encrypted files reach the cloud.
- **Password-derived keys.** The encryption key comes from the user's password plus a random salt, and is never stored.
- **Three layers of login.** Password, then email OTP, then PIN.
- **PIN for sensitive actions.** Upload, view and download all ask for the PIN, with lockout after repeated wrong tries.
- **Tamper detection.** A SHA-256 hash is checked on every open or download.
- **Hidden file names.** Real file names never appear in S3.
- **Auto logout** after inactivity.
- **Recovery key** so a forgotten password doesn't mean lost documents.

## 4. Current Status

| Component | Status |
|---|---|
| Encryption, hashing, S3 + MongoDB storage | Done |
| Login: password, OTP, PIN, lockout | Done |
| Web app (Streamlit): dashboard, upload, my documents, security, profile | Done |
| REST API (FastAPI), deployed on Render | Done |
| Android app (Flutter), using the same API | Working, under active development |
| iOS / macOS / desktop builds | Planned (Flutter project folders exist, not yet targeted) |

## 5. How It Works

### Upload flow
1. User picks a file (max 25 MB) and enters PIN + password.
2. Server checks the PIN (with lockout) and the password.
3. A random 16-byte salt is generated, and a key is derived from password + salt using PBKDF2-SHA256 (100,000 iterations).
4. The file is encrypted with that key (Fernet: AES with HMAC-SHA256 authentication).
5. A SHA-256 hash of the encrypted file is calculated.
6. The encrypted file goes to **AWS S3** under a random name. The metadata goes to **MongoDB**.

### View / download flow
1. User enters PIN (checked with lockout) and password.
2. Server fetches the encrypted file from S3 and recomputes its hash.
3. If the hash doesn't match the stored one, the file is flagged **Tampered** and not opened.
4. If it matches, the file is decrypted and returned.

## 6. Security Design

### Encryption
Files are encrypted using Fernet from Python's `cryptography` library. Fernet uses AES (128-bit key) in CBC mode, plus an HMAC-SHA256 check, so any modification of the encrypted data is also caught during decryption.

### Key management
- Key = PBKDF2(password, random salt), 100,000 iterations.
- A new salt is generated for every file, so the same password gives a different key each time. This blocks rainbow-table and bulk brute-force attacks.
- The key is never saved. It is rebuilt from the password each time.

### Recovery key
A recovery key is shown once at signup. The account password is stored only in encrypted form, locked with a key derived from the recovery key. If the password is forgotten, the recovery key restores access. If both are lost, files can't be decrypted. This is by design.

### File name protection
- S3 objects use random names (`email_uuid.enc`), so real names never appear in storage.
- The real name is stored encrypted with the user's password, and a second copy is encrypted with a server master key so the document list can show names without asking for the password.

### Integrity (SHA-256)
The hash of each encrypted file is stored in MongoDB and compared on every access. A mismatch means the file changed and is shown as Tampered.

### Authentication
| Step | What happens |
|---|---|
| 1. Password | Checked against the stored hash |
| 2. Email OTP | 6-digit code sent by email, valid for 5 minutes |
| 3. PIN | Final step before access is granted |
| Session | Login steps must finish within 15 minutes, then a JWT is issued (12 hours) |
| Auto logout | Web: after inactivity. Mobile: 15-minute timeout |
| PIN lockout | 5 wrong attempts locks that action for 60 seconds |

Other account options: forgot PIN, recover password, change PIN, edit profile, delete account.

## 7. Features

**Account:** sign up, login with OTP + PIN, password recovery, PIN reset, profile editing, account deletion.

**Documents:** upload, folders, list with details, view, download, delete, security status badge (Encrypted / Verified / Tampered).

**Dashboard:** total documents, recent activity, storage usage, security status.

**App experience:** web app and Android app, light and dark themes, in-app legal and privacy screen.

## 8. Tech Stack

| Layer | Technology |
|---|---|
| Web frontend | Streamlit |
| Mobile app | Flutter (Dart), Provider, secure token storage |
| Backend API | FastAPI + Uvicorn, JWT (PyJWT) |
| Encryption | Python `cryptography` (Fernet, PBKDF2) |
| Integrity | SHA-256 (`hashlib`) |
| File storage | AWS S3 (ap-south-1) via boto3 |
| Database | MongoDB (users, documents, folders, login sessions, lockouts) |
| OTP email | Resend API |
| API hosting | Render |

## 9. Database Design

- **users:** name, email, phone, hashed password, hashed PIN, recovery data.
- **documents:** user, encrypted names, S3 key, file hash, salt, size, folder.
- **folders:** user's folder names.
- **login_sessions:** temporary login progress (auto-expires).
- **lockouts:** wrong-PIN attempt counters.

## 10. Estimated Cost

| Stage | Estimate |
|---|---|
| Development / testing (S3 ~1-2 GB, free-tier requests) | ₹50-60 / month |
| 100 users at ~50 MB each | ₹80-150 / month |

*S3 priced at about ₹1.9 per GB per month. API hosting cost depends on the Render plan used.*

## 11. Limitations

- Needs an internet connection.
- A small delay on upload and open because of encryption and hash checks.
- The whole file is processed in memory, so uploads are capped at 25 MB.
- The password is sent to the server (over HTTPS) to encrypt and decrypt, so the server briefly handles it in memory.

## 12. Outcome

A working vault on web and Android where documents are encrypted before storage, checked for tampering on every access, and protected by password, OTP and PIN.

## 13. Future Scope

- Upgrade to AES-256-GCM, and move decryption to the user's device so the password never reaches the server.
- Automatic detection and masking of sensitive data (Aadhaar, PAN) using OCR before encryption.
- Release on iOS and macOS from the same Flutter code.
- Enterprise use (banks, hospitals, legal, government): role-based access, secure sharing and audit logs.
- Automatic document classification.
- Paid tier with more storage and advanced security features.

---

## Screenshots

<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM (2).jpeg" alt="DocLok screen" width="200">
  <img src="WhatsApp Image 2026-09-13 at 2.45.05 PM.jpeg" alt="DocLok screen" width="200">
</p>
<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM (1).jpeg" alt="DocLok screen" width="200">
  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM.jpeg" alt="DocLok screen" width="200">
</p>
<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 3.01.30 PM.jpeg" alt="DocLok screen" width="200">
  <img src="WhatsApp Image 2026-09-13 at 3.01.29 PM.jpeg" alt="DocLok screen" width="200">
</p>
