import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_shell.dart';

class LoginPinScreen extends StatefulWidget {
  final String loginSessionToken;

  const LoginPinScreen({
    super.key,
    required this.loginSessionToken,
  });

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  final _pinController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pinController.text.trim().length < 4) {
      setState(() => _error = 'Enter your 4-digit PIN');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.verifyPin(
        loginSessionToken: widget.loginSessionToken,
        pin: _pinController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ),
        (route) => false,
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

  Future<void> _showForgotPinDialog() async {
    final newPinController = TextEditingController();
    String? dialogError;
    bool dialogLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: !dialogLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> resetPin() async {
              final newPin = newPinController.text.trim();

              if (newPin.length != 4) {
                setDialogState(() {
                  dialogError = 'Enter a 4-digit PIN';
                });
                return;
              }

              setDialogState(() {
                dialogLoading = true;
                dialogError = null;
              });

              try {
                await ApiService.forgotPin(
                  loginSessionToken: widget.loginSessionToken,
                  newPin: newPin,
                );

                if (!context.mounted) return;

                Navigator.of(context).pop();

                Navigator.of(this.context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const HomeShell(),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (context.mounted) {
                  setDialogState(() {
                    dialogError = e.toString();
                    dialogLoading = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Forgot PIN?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter a new 4-digit PIN to reset your security PIN.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: newPinController,
                    label: 'New PIN',
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: TextStyle(
                        color: context.colors.dangerTx,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: dialogLoading ? null : resetPin,
                  child: dialogLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reset PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    newPinController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Icon(
                Icons.pin_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text('Enter your 4-digit security PIN'),
              const SizedBox(height: 24),

              AppTextField(
                controller: _pinController,
                label: 'PIN',
                obscureText: true,
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

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Unlock',
                loading: _loading,
                onPressed: _submit,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _showForgotPinDialog,
                child: const Text('Forgot PIN?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}