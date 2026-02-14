import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class FabActionSheet extends StatelessWidget {
  final VoidCallback onAddHabit;
  final VoidCallback onAddJournal;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onStartFocus;
  final VoidCallback onAddCook;

  const FabActionSheet({
    super.key,
    required this.onAddHabit,
    required this.onAddJournal,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onStartFocus,
    required this.onAddCook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tambah cepat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // grid actions
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  _ActionTile(
                    icon: Icons.checklist_rounded,
                    title: 'Habit',
                    bg: const Color(0xFFFFF1F2),
                    fg: AppColors.pink500,
                    onTap: () {
                      Get.back();
                      onAddHabit();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Journal',
                    bg: const Color(0xFFFCE7F3),
                    fg: AppColors.pink500,
                    onTap: () {
                      Get.back();
                      onAddJournal();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.timer_rounded,
                    title: 'Focus',
                    bg: const Color(0xFFFFEDD5),
                    fg: AppColors.orange400,
                    onTap: () {
                      Get.back();
                      onStartFocus();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.add_card_rounded,
                    title: 'Income',
                    bg: const Color(0xFFD1FAE5),
                    fg: AppColors.emerald500,
                    onTap: () {
                      Get.back();
                      onAddIncome();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.remove_circle_outline_rounded,
                    title: 'Expense',
                    bg: const Color(0xFFDCFCE7),
                    fg: AppColors.emerald500,
                    onTap: () {
                      Get.back();
                      onAddExpense();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Cook',
                    bg: const Color(0xFFFEF3C7),
                    fg: const Color(0xFFF59E0B),
                    onTap: () {
                      Get.back();
                      onAddCook();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // note kecil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: const Text(
                  'Tip: nanti action di atas bisa langsung simpan ke Supabase.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: fg),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}
