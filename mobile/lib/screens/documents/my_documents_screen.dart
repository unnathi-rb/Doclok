import 'dart:convert';

import 'package:flutter/material.dart';
import 'document_viewer_screen.dart';

// import 'package:open_filex/open_filex.dart';
import '../../services/api_service.dart';
import '../../models/document_item.dart';
import 'unlock_document_sheet.dart';
import 'upload_screen.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  List<DocumentItem> _documents = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final docs = await ApiService.listDocuments();

    if (!mounted) return;

    setState(() => _documents = docs);
  } catch (e) {
    if (!mounted) return;

    setState(() => _error = e.toString());
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  List<DocumentItem> get _filtered {
    if (_query.trim().isEmpty) return _documents;
    final q = _query.toLowerCase();
    return _documents
        .where((d) => d.displayName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openUploadScreen() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    if (uploaded == true) _load();
  }

  Future<void> _viewOrDownload(DocumentItem doc) async {
    final password = await showUnlockDocumentSheet(context, doc.id);
    if (password == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Decrypting…'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await ApiService.decryptDocument(
        docId: doc.id,
        password: password,
      );

      final bytes = base64Decode(result['file_base64']);

      if (!mounted) return;

      if (result['integrity'] == 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Integrity verified.'),
          ),
        );
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            filename: result['filename'],
            bytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final isTamperError =
          e.toString().toLowerCase().contains('tamper');

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            isTamperError
                ? '⚠️ Tamper detected'
                : 'Couldn\'t open document',
          ),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  Future<void> _delete(DocumentItem doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${doc.displayName}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteDocument(doc.id);
      setState(() => _documents.removeWhere((d) => d.id == doc.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openUploadScreen,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search documents',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final docs = _filtered;
    if (docs.isEmpty) {
      return Center(
        child: Text(
          _documents.isEmpty
              ? 'No documents yet. Tap + to upload one.'
              : 'No documents match your search.',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final doc = docs[i];
          return ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(doc.displayName),
            subtitle: Text('${doc.sizeKb} KB · ${doc.date.split('T').first}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(doc),
            ),
            onTap: () => _viewOrDownload(doc),
          );
        },
      ),
    );
  }
}
