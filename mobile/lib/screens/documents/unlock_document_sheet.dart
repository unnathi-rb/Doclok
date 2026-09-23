import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Shows a two-step PIN → password sheet. Returns the entered password
/// once the PIN has been verified server-side, or null if the user
/// cancels. The caller uses the returned password to call decryptDocument.
Future<String?> showUnlockDocumentSheet(BuildContext context, String docId) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _UnlockDocumentSheet(docId: docId),
  );
}

class _UnlockDocumentSheet extends StatefulWidget {
  final String docId;
  const _UnlockDocumentSheet({required this.docId});

  @override
  State<_UnlockDocumentSheet> createState() => _UnlockDocumentSheetState();
}

class _UnlockDocumentSheetState extends State<_UnlockDocumentSheet> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _pinVerified = false;
  bool _loading = false;
  String? _error;

  Future<void> _verifyPin() async {
    if (_pinController.text.trim().length < 4) {
      setState(() => _error = 'Enter your 4-digit PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.verifyDocumentPin(
        docId: widget.docId,
        pin: _pinController.text.trim(),
      );
      setState(() => _pinVerified = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submitPassword() {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _pinVerified ? 'Enter your password' : 'Enter your PIN',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (!_pinVerified)
            AppTextField(
              controller: _pinController,
              label: 'PIN',
              obscureText: true,
              keyboardType: TextInputType.number,
            )
          else
            AppTextField(
              key: const ValueKey('password_field'),
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
              keyboardType: TextInputType.text,
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: context.colors.dangerTx)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: _pinVerified ? 'Unlock' : 'Verify PIN',
            loading: _loading,
            onPressed: _pinVerified ? _submitPassword : _verifyPin,
          ),
        ],
      ),
    );
  }
}
