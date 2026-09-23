import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_pin_screen.dart';

class LoginOtpScreen extends StatefulWidget {
  final String loginSessionToken;
  final String email;

  const LoginOtpScreen({
    super.key,
    required this.loginSessionToken,
    required this.email,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _error = 'Enter the OTP sent to your email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.verifyOtp(
        loginSessionToken: widget.loginSessionToken,
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginPinScreen(
            loginSessionToken: widget.loginSessionToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });

    try {
      final result = await ApiService.resendOtp(
        loginSessionToken: widget.loginSessionToken,
      );

      if (!mounted) return;

      setState(() {
        _info = result['message'] ?? 'A new OTP has been sent.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Icon(
                Icons.mail_outline,
                size: 56,
              ),
              const SizedBox(height: 16),

              Text('We sent a code to ${widget.email}'),

              const SizedBox(height: 24),

              AppTextField(
                controller: _otpController,
                label: 'Enter OTP',
                keyboardType: TextInputType.number,
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

              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(
                  _info!,
                  style: TextStyle(
                    color: context.colors.successTx,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Verify',
                loading: _loading,
                onPressed: _verify,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Resending...' : 'Resend OTP',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}