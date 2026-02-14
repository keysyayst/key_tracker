import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing; // Tambahan: Untuk Switch atau panah
  final Color? iconColor; // Tambahan: Untuk warna icon (misal merah saat logout)
  final Color? textColor; // Tambahan: Untuk warna teks

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textDark).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textDark, // Pakai warna custom jika ada
              ),
            ),
            const SizedBox(width: 14),
            
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? AppColors.textDark, // Pakai warna custom jika ada
                ),
              ),
            ),

            // Trailing (Switch / Panah)
            if (trailing != null)
              trailing!
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
