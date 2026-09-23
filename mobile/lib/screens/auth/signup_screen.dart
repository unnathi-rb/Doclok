import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../legal/legal_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _agreedToLegal = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreedToLegal) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        pin: _pinController.text.trim(),
      );

      if (!mounted) return;

      await _showRecoveryKeyDialog(result['recovery_key']);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showRecoveryKeyDialog(String recoveryKey) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Save your recovery key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is shown only once. Store it somewhere safe — '
              "you'll need it if you forget your password.",
            ),
            const SizedBox(height: 16),
            SelectableText(
              recoveryKey,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("I've saved it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Full name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter your phone number'
                          : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password (min 8 characters)',
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 8)
                          ? 'Password must be 8+ characters'
                          : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _pinController,
                  label: '4-digit security PIN',
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.length < 4)
                          ? 'PIN must be 4 digits'
                          : null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: context.colors.dangerTx,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Privacy Policy & Terms consent
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToLegal,
                      onChanged: _loading
                          ? null
                          : (value) {
                              setState(() {
                                _agreedToLegal = value ?? false;
                              });
                            },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          children: [
                            const Text('I agree to the '),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LegalScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Privacy Policy & Terms',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                PrimaryButton(
                  label: 'Create account',
                  loading: _loading,
                  onPressed: _agreedToLegal ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}