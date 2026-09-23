import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_password_screen.dart';
import '../documents/my_documents_tab.dart';
import '../documents/upload_screen.dart';
import '../security/security_tab.dart';
import '../profile/profile_screen.dart';
import '../../widgets/initials_avatar.dart';
import 'home_dashboard_tab.dart';

/// Bottom-nav shell holding the four main sections (mirrors the original
/// Streamlit sidebar: Home, Upload, My Documents, Security). Profile is
/// reached via the avatar in the app bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _userName = '';
  bool _insideFolder = false;

  Timer? _sessionTimer;

  final _myDocumentsKey = GlobalKey<MyDocumentsTabState>();

  static const _titles = [
    'DocLok',
    'Upload',
    'My Documents',
    'Security',
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
    _startSessionTimer();
  }

  /// Starts the 15-minute automatic session timeout.
  void _startSessionTimer() {
    _sessionTimer = Timer(
      const Duration(minutes: 15),
      _handleSessionTimeout,
    );
  }

  /// Clears the token and returns the user to the login screen.
  Future<void> _handleSessionTimeout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPasswordScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _loadName() async {
    try {
      final profile = await ApiService.getProfile();

      if (mounted) {
        setState(() => _userName = profile['name'] ?? '');
      }
    } catch (_) {
      // Non-fatal — avatar just shows a default initial.
    }
  }

  Widget? _buildFab() {
    if (_index != 2) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        final state = _myDocumentsKey.currentState;

        if (_insideFolder) {
          state?.uploadHere();
        } else {
          state?.createFolder();
        }
      },
      icon: Icon(
        _insideFolder
            ? Icons.upload_file
            : Icons.create_new_folder,
      ),
      label: Text(
        _insideFolder ? 'Upload here' : 'New folder',
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              ),
              child: InitialsAvatar(name: _userName),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: IndexedStack(
        index: _index,
        children: [
          const HomeDashboardTab(),
          const UploadScreen(embedded: true),
          MyDocumentsTab(
            key: _myDocumentsKey,
            onFolderContextChanged: (inside) =>
                setState(() => _insideFolder = inside),
          ),
          const SecurityTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Security',
          ),
        ],
      ),
    );
  }
}