import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() =>
      _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState
    extends State<RecoverPasswordScreen> {
  final _emailController = TextEditingController();
  final _recoveryKeyController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _password;

  @override
  void dispose() {
    _emailController.dispose();
    _recoveryKeyController.dispose();
    super.dispose();
  }

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();
    final recoveryKey = _recoveryKeyController.text.trim();

    setState(() {
      _error = null;
      _password = null;
    });

    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    if (recoveryKey.isEmpty) {
      setState(() => _error = 'Enter your recovery key.');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.recoverPassword(
        email: email,
        recoveryKey: recoveryKey,
      );

      if (!mounted) return;

      setState(() {
        _password = result['password']?.toString();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Password'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.key_outlined,
              size: 56,
            ),

            const SizedBox(height: 16),

            const Text(
              'Recover your password',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Enter your email and recovery key to retrieve your password.',
              style: TextStyle(
                color: context.colors.textMuted,
              ),
            ),

            const SizedBox(height: 28),

            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _recoveryKeyController,
              label: 'Recovery Key',
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  color: context.colors.dangerTx,
                ),
              ),
            ],

            if (_password != null) ...[
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: context.colors.successTx,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Your password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      SelectableText(
                        _password!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Use it to log in. Consider changing it afterward from Profile.',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Recover Password',
              loading: _loading,
              onPressed: _recoverPassword,
            ),
          ],
        ),
      ),
    );
  }
}