import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_otp_screen.dart';
import 'signup_screen.dart';
import 'recover_password_screen.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.loginWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginOtpScreen(
            loginSessionToken: result['login_session_token'],
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 40),

                const Icon(
                  Icons.lock_outline,
                  size: 56,
                ),

                const SizedBox(height: 16),

                const Text(
                  'DocLok',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text('Sign in to your vault'),

                const SizedBox(height: 32),

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
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 8)
                          ? 'Password must be 8+ characters'
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

                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Continue',
                  loading: _loading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RecoverPasswordScreen(),
                            ),
                          ),
                  child: const Text('Forgot Password?'),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  ),
                  child: const Text(
                    "Don't have an account? Sign up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}