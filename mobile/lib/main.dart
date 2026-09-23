import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/auth/login_password_screen.dart';
import 'screens/home/home_shell.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const DocLokApp(),
    ),
  );
}

class DocLokApp extends StatelessWidget {
  const DocLokApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'DocLok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      home: const _StartupGate(),
    );
  }
}

/// Checks whether a stored access token is still valid before opening Home.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  Future<bool> _isSessionValid() async {
    final token = await SecureStorageService.getAccessToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await ApiService.getProfile();
      return true;
    } catch (_) {
      await SecureStorageService.clearAccessToken();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isSessionValid(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isValid = snapshot.data ?? false;

        return isValid
            ? const HomeShell()
            : const LoginPasswordScreen();
      },
    );
  }
}