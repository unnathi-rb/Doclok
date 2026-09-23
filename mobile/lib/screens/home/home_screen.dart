import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_password_screen.dart';
import '../documents/my_documents_screen.dart';
import '../documents/upload_screen.dart';
import 'security_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await ApiService.getProfile();
      setState(() => _profile = profile);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPasswordScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DocLok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_profile?['name'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(_profile?['email'] ?? ''),

                        const SizedBox(height: 32),

                        // My Documents
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: const Text('My Documents'),
                            subtitle: const Text(
                              'View, download, delete, search',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyDocumentsScreen(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Upload
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.upload_file_outlined,
                            ),
                            title: const Text('Upload a document'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UploadScreen(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Security
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.security_outlined,
                            ),
                            title: const Text('Security'),
                            subtitle: const Text('Change your PIN'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SecurityScreen(),
                              ),
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