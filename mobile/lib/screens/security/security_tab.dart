import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_title.dart';
import '../../widgets/app_badge.dart';

class _SecurityItem {
  final String title;
  final String desc;
  final String status;
  final IconData icon;
  const _SecurityItem(this.title, this.desc, this.status, this.icon);
}

const _securityItems = [
  _SecurityItem(
    'File encryption — AES-256',
    'Every file is encrypted using a 256-bit key before it is saved. The '
        'key comes from your own password so only you can open your files '
        '— not even the server can read them.',
    'Active',
    Icons.enhanced_encryption_outlined,
  ),
  _SecurityItem(
    'Two-step login (OTP)',
    'After entering your password, a one-time code is sent to your '
        'email. Even if someone has your password, they cannot log in '
        'without that code.',
    'Enabled',
    Icons.mark_email_read_outlined,
  ),
  _SecurityItem(
    'Access PIN',
    'A 4-digit PIN is required every time you view, upload, or download '
        'a file. This adds an extra lock even when you are already logged '
        'in.',
    'Set',
    Icons.pin_outlined,
  ),
  _SecurityItem(
    'Tamper detection — SHA-256',
    'Every file gets a unique fingerprint when saved. Each time you open '
        'or download it, the fingerprint is checked. If anything changed '
        'you will be warned immediately.',
    'All files verified',
    Icons.fingerprint,
  ),
  _SecurityItem(
    'Automatic logout',
    'If you have not done anything for 15 minutes, you will be logged '
        'out automatically. This protects your vault on shared or public '
        'devices.',
    '15 min timeout',
    Icons.timer_outlined,
  ),
];

class SecurityTab extends StatefulWidget {
  const SecurityTab({super.key});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _updatePin() async {
    final newPin = _newPinController.text.trim();
    if (_currentPinController.text.trim().length < 4) {
      setState(() => _error = 'Enter your current PIN');
      return;
    }
    if (newPin.length < 4) {
      setState(() => _error = 'New PIN must be at least 4 digits');
      return;
    }
    if (newPin != _confirmPinController.text.trim()) {
      setState(() => _error = 'The new PINs you entered do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.updatePin(
        currentPin: _currentPinController.text.trim(),
        newPin: newPin,
      );
      if (!mounted) return;
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully.')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle('CHANGE YOUR ACCESS PIN'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              AppTextField(
                controller: _currentPinController,
                label: 'Current PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newPinController,
                label: 'New PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmPinController,
                label: 'Confirm PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: TextStyle(color: c.dangerTx)),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Update PIN',
                loading: _loading,
                onPressed: _updatePin,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('SECURITY OVERVIEW'),
        ..._securityItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.indigo50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 20, color: c.indigo600),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: c.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.desc,
                            style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          AppBadge(label: item.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
