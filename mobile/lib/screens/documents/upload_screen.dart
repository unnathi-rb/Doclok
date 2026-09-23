import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/folder_item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'create_folder_dialog.dart';

class UploadScreen extends StatefulWidget {
  /// Pre-selects this folder when uploading from inside a folder.
  /// null means upload to the root.
  final String? initialFolder;

  /// When true, this screen is embedded inside HomeShell.
  /// When false, it works as a normal standalone screen.
  final bool embedded;

  const UploadScreen({
    super.key,
    this.initialFolder,
    this.embedded = false,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _pickedFile;
  String? _pickedFileName;
  bool _uploading = false;
  String? _error;

  List<FolderItem> _folders = [];
  String? _selectedFolder;
  bool _loadingFolders = true;

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.initialFolder;
    _loadFolders();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await ApiService.listFolders();

      if (mounted) {
        setState(() => _folders = folders);
      }
    } catch (_) {
      // Non-fatal — upload still works without folder selection.
    } finally {
      if (mounted) {
        setState(() => _loadingFolders = false);
      }
    }
  }

  Future<void> _pickFile() async {
    // Keep the original working file picker implementation.
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
        _pickedFileName = result.files.single.name;
        _error = null;
      });
    }
  }

  Future<void> _createFolderInline() async {
    final name = await showCreateFolderDialog(context);

    if (name == null) return;

    await _loadFolders();

    if (mounted) {
      setState(() => _selectedFolder = name);
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      setState(() => _error = 'Choose a file first');
      return;
    }

    if (_pinController.text.trim().length < 4) {
      setState(() => _error = 'Enter your 4-digit PIN');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      await ApiService.uploadDocument(
        file: _pickedFile!,
        pin: _pinController.text.trim(),
        password: _passwordController.text,
        folder: _selectedFolder,
      );

      if (!mounted) return;

      if (widget.embedded) {
        // Embedded in HomeShell: reset the form instead of popping.
        setState(() {
          _pickedFile = null;
          _pickedFileName = null;
          _pinController.clear();
          _passwordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded.'),
          ),
        );
      } else {
        // Standalone screen: signal the caller to refresh.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildForm(context);

    if (widget.embedded) {
      return SafeArea(
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload document'),
      ),
      body: SafeArea(
        child: content,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _pickedFileName ?? 'Choose a file',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'FOLDER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 8),

          if (_loadingFolders)
            const LinearProgressIndicator()
          else
            Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                border: Border.all(
                  color: c.border,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedFolder,
                  isExpanded: true,
                  hint: const Text('Root (no folder)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Root (no folder)'),
                    ),
                    ..._folders.map(
                      (folder) => DropdownMenuItem<String?>(
                        value: folder.name,
                        child: Text(folder.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFolder = value;
                    });
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _createFolderInline,
              icon: const Icon(
                Icons.create_new_folder_outlined,
                size: 18,
              ),
              label: const Text('New folder'),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Your PIN and password are checked again here, even '
            "though you're already logged in — that's what keeps "
            'each upload individually protected.',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _pinController,
            label: 'PIN',
            obscureText: true,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: true,
            keyboardType: TextInputType.text,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: c.dangerTx,
              ),
            ),
          ],

          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Upload',
            loading: _uploading,
            onPressed: _upload,
          ),
        ],
      ),
    );
  }
}