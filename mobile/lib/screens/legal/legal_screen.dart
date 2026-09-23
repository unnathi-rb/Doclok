import 'package:flutter/material.dart';


class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Terms'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DocLok',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Privacy Policy & Terms of Service',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Effective Date: September 2026\n'
                'Last Updated: September 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // Important Security Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Important: Protect Your Account',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are responsible for keeping your password, PIN, '
                      'recovery key, and registered email account secure.\n\n'
                      'Your recovery key is shown only once when you create '
                      'your DocLok account. Please store it safely.\n\n'
                      'If you lose both your password and recovery key, '
                      'access to your encrypted documents may be permanently '
                      'lost. DocLok does not maintain a master password or '
                      'intentional backdoor to bypass your account security.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const _LegalSection(
                title: '1. Information We Collect',
                text:
                    'DocLok collects information required to create and secure '
                    'your account, including your name, email address, phone '
                    'number, password-related security information, PIN, and '
                    'recovery information.\n'
                    'You may also upload personal documents such as identity '
                    'documents, certificates, financial records, medical '
                    'documents, and other files that you choose to store.\n'
                    'DocLok also stores information needed to manage your '
                    'documents, such as file size, upload date, file integrity '
                    'information, and folder information.',
              ),

              const _LegalSection(
                title: '2. How We Use Your Information',
                text:
                    'We use your information to:\n'
                    '• Create and manage your account\n'
                    '• Authenticate your login using password, OTP, and PIN\n'
                    '• Store and retrieve your documents\n'
                    '• Organize your documents\n'
                    '• Verify document integrity\n'
                    '• Maintain the security and operation of DocLok\n'
                    '• Provide user support\n'
                    'We do not use your uploaded document contents for '
                    'advertising or unrelated purposes.',
              ),

              const _LegalSection(
                title: '3. Document Security',
                text:
                    'DocLok encrypts uploaded documents before they are stored '
                    'in cloud storage. Document filenames are also encrypted.\n\n'
                    'The system is designed so that the backend does not '
                    'ordinarily have access to the readable contents of your '
                    'encrypted documents.\n'
                    'However, no online service can guarantee absolute security.\n'
                    'Folder names are currently stored as plain text and are '
                    'not encrypted. Please avoid including sensitive personal '
                    'information in folder names.',
              ),

              const _LegalSection(
                title: '4. Password, PIN & Recovery Key',
                text:
                    'Your password, PIN, recovery key, and registered email '
                    'account are important security components of your DocLok '
                    'account.\n\n'
                    'You are responsible for keeping them confidential.\n'
                    'Your recovery key is provided once during account creation. '
                    'If you lose both your password and recovery key, DocLok '
                    'may not be able to restore access to your encrypted '
                    'documents.',
              ),

              const _LegalSection(
                title: '5. Third-Party Services',
                text:
                    'DocLok uses third-party services to operate the application:\n\n'
                    '• Render — backend/application hosting\n'
                    '• MongoDB Atlas — account and database information\n'
                    '• AWS S3 — encrypted document storage\n'
                    'AWS provides security, encryption, access-control, compliance, '
                    'and data-residency capabilities that can support DocLok’s security '
                    'and privacy obligations. DocLok remains responsible for configuring '
                    'these services appropriately and complying with applicable laws.\n'
                    'Third-party services may process information required to provide '
                    'their respective functions.',
                ),

              const _LegalSection(
                title: '6. Your Documents',
                text:
                    'You retain ownership of the documents you upload to '
                    'DocLok.\n'
                    'You are responsible for ensuring that you have the legal '
                    'right to store the documents you upload.\n'
                    'You must not use DocLok to store unlawful content, '
                    'malicious files, or content intended to compromise the '
                    'service or another user’s account.',
              ),

              const _LegalSection(
                title: '7. Data Retention & Account Deletion',
                text:
                    'Your account information and uploaded documents are '
                    'stored while you use DocLok.\n'
                    'You can delete individual documents or your account '
                    'through the available application features.\n'
                    'When you delete your account, DocLok is designed to '
                    'permanently delete your account information, associated '
                    'document data, folders, and stored documents from its '
                    'active systems.\n'
                    'Account deletion is irreversible.',
              ),

              const _LegalSection(
                title: '8. Service Availability',
                text:
                    'DocLok is provided “as is” and “as available”.\n'
                    'We aim to provide a reliable service but cannot guarantee '
                    'uninterrupted access. The service may be affected by '
                    'maintenance, technical problems, network failures, '
                    'security incidents, or third-party service outages.',
              ),

              const _LegalSection(
                title: '9. Privacy Rights',
                text:
                    'Depending on applicable law, you may have rights relating '
                    'to your personal information, including requesting access, '
                    'correction, or deletion of your information.\n'
                    'For privacy questions or requests, contact:',
              ),

              const _ContactCard(
                email: 'doclok1234@gmail.com',
              ),

              const _LegalSection(
                title: '10. Changes & Acceptance',
                text:
                    'We may update this Privacy Policy & Terms of Service when '
                    'DocLok’s features, data practices, or legal requirements '
                    'change.\n'
                    'The latest version will be made available through the '
                    'application.\n'
                    'By creating a DocLok account, you confirm that you have '
                    'read and agree to this Privacy Policy & Terms of Service.',
              ),

              const SizedBox(height: 8),

              const _ContactCard(
                email: 'doclok1234@gmail.com',
                showTitle: true,
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  '© September 2026 DocLok',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String text;

  const _LegalSection({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String email;
  final bool showTitle;

  const _ContactCard({
    required this.email,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              'Contact',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'DocLok Support',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}