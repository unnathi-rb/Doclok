import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String filename;
  final Uint8List bytes;

  const DocumentViewerScreen({
    super.key,
    required this.filename,
    required this.bytes,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _saving = false;

  bool get _isImage {
    final name = widget.filename.toLowerCase();

    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp');
  }

  Future<void> _download() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await FlutterFileSaver().writeFileAsBytes(
        fileName: widget.filename,
        bytes: widget.bytes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save file: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filename,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isImage
          ? Center(
              child: InteractiveViewer(
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.filename,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This file type cannot be previewed inside DocLok yet.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _download,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                _saving ? 'Saving...' : 'Download',
              ),
            ),
          ),
        ),
      ),
    );
  }
}