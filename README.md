# DocLok: Cloud Document Vault

## Problem Statement

In today's digital world, individuals increasingly rely on online platforms to store and manage important personal documents such as identity proofs, academic certificates, medical records, bank-related documents, and even property papers. This shift has made access and sharing more convenient, especially in situations like job applications, financial processes, or healthcare needs. However, this convenience also brings growing concerns about the safety and privacy of sensitive information.

Many users are often unaware of how securely their documents are handled once uploaded, and there is always a risk of unauthorized access, data exposure, or misuse of personal information. Since these documents contain highly confidential details, any compromise can lead to serious consequences, including cyber theft or financial fraud.

Ensuring that such critical information remains private, protected, and trustworthy has therefore become increasingly important. This creates a clear need for a more secure and reliable approach to digital document management where it not only provides accessibility, but also prioritizes data protection and gives users better control over their own information.

## Target Audience

DocLok is designed for individuals such as students, job seekers, working professionals, and families who need a secure way to manage important documents like identity proofs, academic certificates, and medical records. It is especially useful for users who frequently share documents for banking, healthcare, or job verification, while wanting to ensure their personal information remains protected.

## Unique Selling Proposition (USP)

- In today's digital era, users frequently upload important documents for tasks like loans, admissions, and verification, making secure storage essential.
- These documents contain sensitive information (bank details, identity numbers, addresses) that can be misused for phishing, fraud, or identity theft if exposed.
- DocLok follows a security-first approach, protecting documents throughout their lifecycle from upload to access.
- Files are encrypted before upload, ensuring that only encrypted data is stored in the cloud.
- The encryption key is derived from the user's password, meaning only the user can access their documents, not even the system.
- This creates a zero-knowledge environment, where even if storage or databases are compromised, data remains unreadable.
- The system includes multi-layer authentication (password, OTP, PIN) for secure access control.
- Tamper detection using hashing ensures file integrity during retrieval.
- By combining strong security with convenience, DocLok provides users with complete control, privacy, and trust for managing sensitive documents.

## Overview and Scope

DocLok is a cloud-based document vault designed with a security-first approach. Instead of simply storing files, the system:

- Encrypts documents before upload
- Verifies file integrity during access
- Adds multiple layers of authentication

The goal is to ensure that documents remain private, tamper-proof, and user-controlled throughout their lifecycle.

## How the Project is Different from Competitors

Most existing platforms focus mainly on storing and sharing documents, with limited protection of the actual content. This project follows a security-first approach, ensuring documents are protected at every stage.

### Key Differentiators

- **Encryption-First**: Documents are encrypted (AES-256) before cloud storage
- **User-Controlled Keys**: Encryption key derived from user password (no server access)
- **MFA at Every Login**: OTP-based authentication for strong identity verification
- **PIN-Based Access**: Additional PIN required for upload, view, and download
- **Session Timeout**: Auto logout after inactivity for safety
- **Tamper Detection**: SHA-256 hashing ensures data integrity
- **Flexible Usage**: Supports various personal documents

## Technical Features

- **AES-256 Encryption**: Ensures strong confidentiality by encrypting documents before storage using a symmetric key algorithm.
- **SHA-256 Hashing**: Generates a unique fingerprint of encrypted files to detect any tampering during retrieval.
- **Multi-Factor Authentication (MFA)**: OTP-based verification adds an extra layer of user authentication.
- **Cloud Storage (AWS S3)**: Stores encrypted documents securely with high availability and scalability.

## System Architecture

### Detailed Processing Flow

#### 1. Document Upload
- User uploads image/PDF via frontend
- File is sent to backend for processing

#### 2. Encryption (AES-256)
- File converted into byte stream
- Encrypted using generated key
- Output: unreadable binary data

#### 3. Hash Generation (SHA-256)
- Hash generated for encrypted file
- Stored for integrity verification

#### 4. Cloud Storage & Metadata Management
- Encrypted file uploaded to AWS S3 bucket as an object
- MongoDB database stores metadata including:
  - File ID
  - User ID
  - Hash
  - Salt
  - S3 Object path

## AES Encryption Mechanism

AES (Advanced Encryption Standard) is a symmetric block cipher that operates on 128-bit data blocks.

### For AES-256:
- **Key size** = 256 bits
- **Number of rounds** = 14

### Each encryption round includes:
- **SubBytes**: Byte substitution using lookup table
- **ShiftRows**: Row-wise shifting
- **MixColumns**: Column-wise mixing
- **AddRoundKey**: Combining data with encryption key

These repeated transformations ensure that the output is highly randomized and secure.

## Encryption Key Management

### User-Based Key Generation

Key derived using:
- User password
- Random salt
- Key Derivation Function (KDF) such as PBKDF2

```
Key = KDF(password + salt)
```

Salt characteristics:
- Randomly generated per file
- Stored with metadata
- Same password → different keys
- Prevents brute-force and rainbow table attacks

### Decryption Process

1. User enters password
2. System retrieves salt
3. Regenerates key using KDF
4. Decrypts file

### Password Recovery Mechanism

Since the encryption key is derived from the user's password, the system cannot directly recover lost passwords. To handle this, a recovery key is generated at the time of encryption and provided to the user. This recovery key can be used to regain access to documents if the password is forgotten, ensuring a balance between strong security and usability.

If both the password and the recovery key are lost, the encrypted documents cannot be decrypted and become permanently inaccessible. This design ensures that encryption keys are never stored within the system, giving users complete control over their data and preventing any unauthorized access, even in the event of a system breach.

## Hashing and Integrity Verification

- SHA-256 used to generate a unique hash
- Hash is stored with file metadata

### During Retrieval (Download OR View)

1. File is fetched from storage
2. Hash is recomputed from the file
3. Compared with the stored hash
4. **If mismatch**: File is tampered

## Authentication & MFA

### Login Password (Primary Authentication)

DocLok uses a password-based login mechanism as the primary level of authentication.

- Users are required to log in every time the application is accessed
- Passwords are securely handled using hashing techniques
- To enhance security, Multi-Factor Authentication (MFA) is implemented using a One-Time Password (OTP)
- An OTP is generated and sent to the user's registered email or mobile number at every login attempt
- Access is granted only after successful OTP verification
- MFA with OTP is enforced at every login to ensure continuous identity verification
- The login password is also used to derive the encryption key through a secure key derivation function, ensuring strong data protection

### Access PIN (Secondary Authorization)

To provide an additional layer of security, the system uses a PIN-based verification mechanism for sensitive actions.

- Users set a secure PIN during account setup
- The PIN is required for:
  - Uploading files
  - Opening files
  - Downloading files
- The PIN acts as a secondary authentication factor within an active session
- Incorrect attempts can be limited to prevent misuse

This approach ensures that even if a session is active, critical operations remain protected through an additional verification step.

## Backend Design

- Implemented using Python within the Streamlit application
- Combines backend logic and frontend interface in a single system
- Handles complete processing pipeline:
  - File upload
  - Encryption (AES-256)
  - Hashing (SHA-256)
- Uses event-driven execution based on user actions (no separate APIs)
- Suitable for small-scale deployment and demonstration
- Can be extended to API-based architecture using Flask or FastAPI for scalability

## Frontend Design

- Built using Streamlit
- Provides a simple and interactive user interface
- Features:
  - File upload interface
  - Document preview
  - Secure download option
- Triggers backend processing based on user actions
- Integrated with backend logic within a single application

## Cloud Storage

### AWS S3

Encrypted documents are stored as objects in AWS S3 using a bucket-based storage system. This approach allows scalable and efficient storage of large files while ensuring security through controlled access policies. Each file is stored with a unique object path (key), which is later used for retrieval.

### Metadata Management (MongoDB Database)

All file-related metadata is stored separately in a MongoDB database to enable efficient management and retrieval. The metadata includes:
- File ID
- User ID
- File hash (for integrity verification)
- Salt (used in encryption key generation)
- S3 object path

### Hybrid Storage Approach

The system follows a hybrid storage approach where encrypted files are stored in AWS S3, while their corresponding metadata is maintained in the database.

**During upload**:
- File is processed, encrypted, and stored in an S3 bucket
- Metadata is simultaneously recorded in MongoDB

**During access**:
- Backend first queries the database to retrieve metadata
- Uses stored S3 path to fetch encrypted file
- File's integrity is verified using the stored hash
- File is securely decrypted and provided to the user

This separation of storage and metadata ensures enhanced security, efficient retrieval, and high scalability.

## Dashboard

### Sidebar Navigation

- Dashboard
- Upload Document
- My Documents
- Security Settings
- Profile
- Logout

### Main Dashboard

- Total documents
- Recent activity
- Storage usage
- Security status (MFA, encryption active)

### Upload Section

- File upload option
- PIN required before upload
- Shows processing and success status

### My Documents Section

- List of uploaded files
- File details (name, date, status)
- Actions: View / Download / Delete
- PIN required for access

### Security Settings

- Set/Update access PIN

### Security Indicators

- Encrypted
- Verified
- Tampered (if any issue)

## Deployment

The system can be deployed using Streamlit Cloud by hosting the Streamlit application directly from a GitHub repository. This allows both the frontend interface and core backend logic to run in a single environment with minimal setup. Encrypted documents are stored separately in Amazon S3, ensuring secure and scalable storage.

This approach is cost-effective, easy to implement, and suitable for small-scale usage and demonstration purposes.

## Cost and Pricing

### For Development and Testing

**Estimated Costs**:
- **Application Hosting** (Streamlit Cloud): Free (under community/free tier)
- **Cloud Storage** (AWS S3): Small usage (approx 1-2 GB): ₹2 - ₹5 per month
- **Data Transfer & Requests**: Minimal usage under free tier: ₹0 - ₹30 per month

**Total**: ₹50-₹60 per month

### For Further Scaling Up

**Assumptions**:
- Avg storage per user: 50 MB
- AWS S3 cost: $0.023/GB/month (₹1.9/GB)

**For 100 Users**:
- Storage: 5 GB around ₹10/month
- Requests & usage: ₹80- ₹100/month
- **Total**: ₹80 - ₹150 per month

## Outcome

- Secure and privacy-focused document storage system
- Protection against unauthorized access
- Tamper-proof document verification
- Increased trust in digital document handling

## Limitations

- Requires internet connectivity (cloud-based system)
- Slight processing delay due to security operations

## Timeline

### Month 1: Core Development
- System setup and architecture
- Document upload and processing pipeline

### Month 2: Security Implementation
- AES encryption implementation
- Hashing for integrity

### Month 3: UI & Final Improvements
- Frontend development
- AWS S3 integration
- Authentication system
- Testing and deployment

## Future Scope

- The system can be extended beyond individual users to support large-scale, high-security environments such as banks, hospitals, legal systems, and government organizations, where handling sensitive documents securely is critical. The encryption-first approach and tamper detection make it highly suitable for such domains.

- For organizational use, the platform can be enhanced with role-based access control, enabling different permission levels for employees and departments, along with features like secure document sharing and audit logs required in regulated industries.

- Advanced capabilities such as automated document classification and multi-factor authentication can be added to further strengthen security and improve efficiency.

- The project can also evolve into a product with basic and advanced access options (Paid version), allowing users and organizations to scale storage and security features based on their needs.

<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM (2).jpeg" alt="DocLok Logo" width="200">
  <img src="WhatsApp Image 2026-09-13 at 2.45.05 PM.jpeg" alt="DocLok Logo" width="200">
</p>

<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM (1).jpeg" alt="DocLok Logo" width="200">

  <img src="WhatsApp Image 2026-09-13 at 2.45.06 PM.jpeg" alt="DocLok Logo" width="200">
</p>
<p align="center">
  <img src="WhatsApp Image 2026-09-13 at 3.01.30 PM.jpeg" alt="DocLok Logo" width="200">
  <img src="WhatsApp Image 2026-09-13 at 3.01.29 PM.jpeg" alt="DocLok Logo" width="200">
</p>



