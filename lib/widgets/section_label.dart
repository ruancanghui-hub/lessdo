import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.count,
    this.bottomBorder = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int? count;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: bottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          if (count != null)
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              height: 28,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF787C84).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Color(0xFF666870), fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
