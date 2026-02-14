import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String category;

  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final style = _style(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: style.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _BadgeStyle _style(String c) {
    switch (c) {
      case 'Spiritual':
        return _BadgeStyle(const Color(0xFFF3E8FF), const Color(0xFFA855F7), const Color(0xFFE9D5FF));
      case 'Health':
        return _BadgeStyle(const Color(0xFFDCFCE7), const Color(0xFF16A34A), const Color(0xFFBBF7D0));
      case 'Learning':
        return _BadgeStyle(const Color(0xFFDBEAFE), const Color(0xFF2563EB), const Color(0xFFBFDBFE));
      case 'Career':
        return _BadgeStyle(const Color(0xFFFFEDD5), const Color(0xFFEA580C), const Color(0xFFFED7AA));
      case 'Finance':
        return _BadgeStyle(const Color(0xFFFEF9C3), const Color(0xFFA16207), const Color(0xFFFEF08A));
      case 'SelfCare':
        return _BadgeStyle(const Color(0xFFFFE4E6), const Color(0xFFE11D48), const Color(0xFFFECACA));
      default:
        return _BadgeStyle(const Color(0xFFF3F4F6), const Color(0xFF6B7280), const Color(0xFFE5E7EB));
    }
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  final Color border;
  _BadgeStyle(this.bg, this.fg, this.border);
}
