import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class PastelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? background;
  final Color? borderColor;

  const PastelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor ?? const Color(0xFFFCE7F3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
