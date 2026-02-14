import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class PastelBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const PastelBottomNav({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget item({
      required int i,
      required IconData icon,
      required Color activeColor,
    }) {
      final active = index == i;
      return InkWell(
        onTap: () => onTap(i),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 26,
            color: active ? activeColor : const Color(0xFFD1D5DB),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.white),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          item(i: 0, icon: Icons.home_rounded, activeColor: AppColors.pink500),
          item(i: 1, icon: Icons.pie_chart_rounded, activeColor: AppColors.purple400),
          const SizedBox(width: 44), // spacer untuk FAB tengah
          item(i: 2, icon: Icons.menu_book_rounded, activeColor: AppColors.blue400),
          item(i: 3, icon: Icons.person_rounded, activeColor: AppColors.orange400),
        ],
      ),
    );
  }
}
