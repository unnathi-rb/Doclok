import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    setState(() {
      _error = null;
      _success = null;
    });

    if (!RegExp(r'^\d{4}$').hasMatch(currentPin)) {
      setState(() => _error = 'Enter your current 4-digit PIN.');
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      setState(() => _error = 'New PIN must be exactly 4 digits.');
      return;
    }

    if (newPin != confirmPin) {
      setState(() => _error = 'New PINs do not match.');
      return;
    }

    if (currentPin == newPin) {
      setState(() => _error = 'New PIN must be different from your current PIN.');
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.updatePin(
        currentPin: currentPin,
        newPin: newPin,
      );

      if (!mounted) return;

      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();

      setState(() {
        _success = 'PIN changed successfully.';
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
        title: const Text('Security'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.security_outlined,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Change your security PIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a 4-digit PIN to protect your DocLok account.',
            ),
            const SizedBox(height: 28),

            AppTextField(
              controller: _currentPinController,
              label: 'Current PIN',
              obscureText: true,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _newPinController,
              label: 'New PIN',
              obscureText: true,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _confirmPinController,
              label: 'Confirm New PIN',
              obscureText: true,
              keyboardType: TextInputType.number,
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            if (_success != null) ...[
              const SizedBox(height: 16),
              Text(
                _success!,
                style: const TextStyle(color: Colors.green),
              ),
            ],

            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Change PIN',
              loading: _loading,
              onPressed: _changePin,
            ),
          ],
        ),
      ),
    );
  }
}