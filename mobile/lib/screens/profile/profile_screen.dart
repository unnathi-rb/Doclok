import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/section_title.dart';
import '../auth/login_password_screen.dart';
import '../legal/legal_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  bool _confirmingDelete = false;
  final _deleteConfirmController = TextEditingController();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _deleteConfirmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPasswordScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _deleting = true);
    try {
      await ApiService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPasswordScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = context.watch<ThemeController>();
    final name = (_profile?['name'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: TextStyle(color: c.dangerTx)),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Identity card ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(name: name, size: 64),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?['email'] ?? '',
                                    style: TextStyle(fontSize: 13, color: c.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  const AppBadge(label: 'Personal vault'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Account details (read-only — backend has no
                      // profile-update endpoint) ─────────────────────
                      const SectionTitle('ACCOUNT DETAILS'),
                      Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Full name'),
                              subtitle: Text(name),
                            ),
                            Divider(height: 1, color: c.border),
                            ListTile(
                              leading: const Icon(Icons.email_outlined),
                              title: const Text('Email'),
                              subtitle: Text(_profile?['email'] ?? ''),
                            ),
                            Divider(height: 1, color: c.border),
                            ListTile(
                              leading: const Icon(Icons.phone_outlined),
                              title: const Text('Phone'),
                              subtitle: Text(
                                (_profile?['phone'] as String?)?.isNotEmpty == true
                                    ? _profile!['phone']
                                    : 'Not set',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Appearance ───────────────────────────────
                      const SectionTitle('APPEARANCE'),
                      Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          secondary: Icon(
                            theme.isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                          ),
                          title: const Text('Dark mode'),
                          value: theme.isDark,
                          onChanged: (v) => theme.toggle(v),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Privacy & Terms ───────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Privacy Policy & Terms of Service'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LegalScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.dangerTx,
                          side: BorderSide(color: c.border),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Danger zone ──────────────────────────────
                      const SectionTitle('DANGER ZONE'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.dangerBg,
                          border: Border.all(color: c.dangerTx.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.dangerTx,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Permanently deletes all your documents and '
                              'account data. Cannot be undone.',
                              style: TextStyle(fontSize: 12, color: c.dangerTx),
                            ),
                            const SizedBox(height: 12),
                            if (!_confirmingDelete)
                              OutlinedButton(
                                onPressed: () =>
                                    setState(() => _confirmingDelete = true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: c.dangerTx,
                                  side: BorderSide(color: c.dangerTx),
                                ),
                                child: const Text('Delete my account'),
                              )
                            else ...[
                              Text(
                                'This will permanently delete all documents '
                                'and account data for ${_profile?['email'] ?? 'this account'}. '
                                'This cannot be undone.',
                                style: TextStyle(fontSize: 12.5, color: c.dangerTx),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _deleteConfirmController,
                                decoration: const InputDecoration(
                                  labelText: 'Type DELETE to confirm',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _deleting
                                          ? null
                                          : () => setState(() {
                                                _confirmingDelete = false;
                                                _deleteConfirmController.clear();
                                              }),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (_deleteConfirmController.text ==
                                                  'DELETE' &&
                                              !_deleting)
                                          ? _deleteAccount
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: c.dangerTx,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                      ),
                                      child: _deleting
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Delete permanently'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
