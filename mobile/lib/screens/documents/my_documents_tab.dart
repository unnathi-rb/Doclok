import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/document_item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/app_badge.dart';
import 'unlock_document_sheet.dart';
import 'upload_screen.dart';
import 'create_folder_dialog.dart';
import 'document_viewer_screen.dart';

/// My Documents tab: root view shows folders + unfiled documents; tapping
/// a folder drills into its contents. Search filters by name within the
/// current scope (all documents at root, or just this folder's contents).
class MyDocumentsTab extends StatefulWidget {
  /// Called whenever the user enters or leaves a folder, so a containing
  /// shell can update its FAB label/action accordingly.
  final ValueChanged<bool>? onFolderContextChanged;

  const MyDocumentsTab({super.key, this.onFolderContextChanged});

  @override
  State<MyDocumentsTab> createState() => MyDocumentsTabState();
}

class MyDocumentsTabState extends State<MyDocumentsTab> {
  List<DocumentItem> _documents = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _openFolder; // null = root

  /// Exposed so the containing shell's FAB can show the right label.
  bool get isInsideFolder => _openFolder != null;

  void _setOpenFolder(String? folder) {
    setState(() => _openFolder = folder);
    widget.onFolderContextChanged?.call(folder != null);
  }

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

  List<String> get _folderNames {
    final names = _documents
        .map((d) => d.folder)
        .whereType<String>()
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();

    names.sort();
    return names;
  }

  int _countInFolder(String folder) =>
      _documents.where((d) => d.folder == folder).length;

  List<DocumentItem> get _rootDocs =>
      _documents.where((d) => d.folder == null || d.folder!.isEmpty).toList();

  List<DocumentItem> get _currentScopeDocs {
    final base = _openFolder == null
        ? _rootDocs
        : _documents.where((d) => d.folder == _openFolder).toList();

    if (_query.trim().isEmpty) return base;

    final q = _query.toLowerCase();

    return base
        .where((d) => d.displayName.toLowerCase().contains(q))
        .toList();
  }

  List<String> get _filteredFolders {
    if (_openFolder != null) return [];

    if (_query.trim().isEmpty) return _folderNames;

    final q = _query.toLowerCase();

    return _folderNames
        .where((f) => f.toLowerCase().contains(q))
        .toList();
  }

  Future<void> createFolder() async {
    final name = await showCreateFolderDialog(context);

    if (name != null) {
      _load();
    }
  }

  Future<void> uploadHere() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UploadScreen(initialFolder: _openFolder),
      ),
    );

    if (uploaded == true) {
      _load();
    }
  }

  Future<void> _deleteFolder(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          '"$name" will be deleted. Documents inside it are NOT deleted — '
          "they'll move back to the root.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.dangerTx),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteFolder(name);

      if (mounted) {
        _setOpenFolder(null);
        _load();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _viewOrDownload(DocumentItem doc) async {
    final password = await showUnlockDocumentSheet(
      context,
      doc.id,
    );

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
                : "Couldn't open document",
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
        content: Text(
          '"${doc.displayName}" will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.dangerTx),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteDocument(doc.id);

      if (mounted) {
        setState(
          () => _documents.removeWhere((d) => d.id == doc.id),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      children: [
        if (_openFolder != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _setOpenFolder(null),
                ),
                Icon(
                  Icons.folder,
                  color: c.indigo600,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _openFolder!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: c.dangerTx,
                  ),
                  tooltip: 'Delete folder',
                  onPressed: () => _deleteFolder(_openFolder!),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InfoBanner(
            text: 'Viewing or downloading a file requires your PIN and your '
                'password. Your password decrypts the file content — it is '
                'never stored.',
          ),
        ),
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
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: context.colors.dangerTx,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final folders = _filteredFolders;
    final docs = _currentScopeDocs;
    final c = context.colors;

    if (folders.isEmpty && docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _documents.isEmpty
                ? 'No documents yet. Use the buttons below to add a folder or upload a file.'
                : 'Nothing matches your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          if (folders.isNotEmpty) ...[
            Text(
              'FOLDERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: folders.length,
              itemBuilder: (context, i) {
                final name = folders[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _query = '');
                    _setOpenFolder(name);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.folder,
                          color: c.indigo600,
                          size: 26,
                        ),
                        const Spacer(),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_countInFolder(name)} document'
                          '${_countInFolder(name) == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (docs.isNotEmpty) ...[
            Text(
              _openFolder == null ? 'UNFILED' : 'DOCUMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: c.border),
                itemBuilder: (context, i) {
                  final doc = docs[i];

                  return InkWell(
                    onTap: () => _viewOrDownload(doc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: c.indigo600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${doc.sizeKb} KB · '
                                  '${doc.date.split('T').first}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(label: doc.status),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            onPressed: () => _delete(doc),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}