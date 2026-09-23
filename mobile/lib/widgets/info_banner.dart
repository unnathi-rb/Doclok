import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_badge.dart';

class InfoBanner extends StatelessWidget {
  final String text;
  final BadgeTone tone;

  const InfoBanner({super.key, required this.text, this.tone = BadgeTone.indigo});

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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: fg, height: 1.4)),
    );
  }
}
