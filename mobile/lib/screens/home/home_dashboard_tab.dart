import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_badge.dart';

class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  int _totalDocs = 0;
  bool _loading = true;
  String? _error;

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
      // No dedicated stats endpoint — derive total documents
      // from the same document list My Documents uses.
      final docs = await ApiService.listDocuments();

      setState(() {
        _totalDocs = docs.length;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context).colorScheme.error,
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(label: 'Session: 15 min timeout'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'TOTAL DOCUMENTS',
                  value: '$_totalDocs',
                  sub: 'Stored securely in your vault',
                  accent: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}