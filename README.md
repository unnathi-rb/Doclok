# DocLok: Secure Cloud Document Vault

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
- **Brute-force protection.** Wrong password, PIN and recovery-key attempts are limited, then locked for a short time.
- **PIN for sensitive actions.** Upload, view and download all ask for the PIN, with lockout after repeated wrong tries.
- **Tamper detection.** A SHA-256 hash is checked on every open or download.
- **Hidden file names.** Real file names never appear in S3.
- **Recovery key** so a forgotten password doesn't mean lost documents.

## 4. How It Works

### Upload flow
1. User picks a file (max 25 MB) and enters PIN + password.
2. Server checks the PIN and the password, both with attempt limits.
3. A random 16-byte salt is generated, and a key is derived from password + salt using PBKDF2-SHA256 (100,000 iterations).
4. The file is encrypted with that key (Fernet: AES with HMAC-SHA256 authentication).
5. A SHA-256 hash of the encrypted file is calculated.
6. The encrypted file goes to **AWS S3** under a random name. The metadata goes to **MongoDB**.

### View / download flow
1. User enters PIN and password, both with attempt limits.
2. Server fetches the encrypted file from S3 and recomputes its hash.
3. If the hash doesn't match the stored one, the file is flagged **Tampered** and not opened.
4. If it matches, the file is decrypted and returned.

## 5. Security Design

### Encryption
Files are encrypted using Fernet (Python `cryptography` library), which combines AES encryption with a tamper-proof seal. The file is scrambled so only the right password can unlock it, and if anyone modifies the stored file, decryption fails instead of returning corrupted data.

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
| Session Timeout  | Auto logout after 15 minutes of inactivity |

Other account options: forgot PIN, recover password, change PIN, edit profile, delete account.

## 6. Features

**Account:** sign up, login with OTP + PIN, password recovery, PIN reset, profile editing, account deletion.

**Documents:** upload, folders, list with details, view, download, delete, security status badge (Encrypted / Verified / Tampered).

**Dashboard:** total documents, recent activity, storage usage, security status.

**App experience:** web app and Android app, light and dark themes, in-app legal and privacy screen.

## 7. Tech Stack

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

## 8. Database Design

- **users:** name, email, phone, hashed password, hashed PIN, recovery data.
- **documents:** user, encrypted names, S3 key, file hash, salt, size, folder.
- **folders:** user's folder names.
- **login_sessions:** temporary login progress (auto-expires).
- **lockouts:** wrong password, PIN and recovery-key attempt counters(5 attempts allowed) .

## 9. Limitations

- Needs an internet connection.
- A small delay on upload and open because of encryption and hash checks.
- The whole file is processed in memory, so uploads are capped at 25 MB.

## 10. Outcome

A working vault on web and Android where documents are encrypted before storage, checked for tampering on every access, and protected by password, OTP and PIN.

## 11. Future Scope

- Release on iOS and macOS from the same Flutter code.
- Enterprise use (banks, hospitals, legal, government): role-based access, secure sharing and audit logs.
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
