import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? valueSuffix;
  final String sub;
  final bool accent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueSuffix,
    required this.sub,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: accent ? c.indigo600 : c.textMain,
                  ),
                ),
                if (valueSuffix != null)
                  TextSpan(
                    text: ' $valueSuffix',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent ? c.indigo600 : c.textMain,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(fontSize: 12.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
