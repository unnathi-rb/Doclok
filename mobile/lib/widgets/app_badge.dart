import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeTone { indigo, success, warning, danger, info }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const AppBadge({super.key, required this.label, this.tone = BadgeTone.indigo});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      BadgeTone.indigo => (c.indigo50, c.indigo800),
      BadgeTone.success => (c.successBg, c.successTx),
      BadgeTone.warning => (c.warningBg, c.warningTx),
      BadgeTone.danger => (c.dangerBg, c.dangerTx),
      BadgeTone.info => (c.infoBg, c.infoTx),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
