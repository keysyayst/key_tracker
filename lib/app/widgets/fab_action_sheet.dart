import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class FabActionSheet extends StatelessWidget {
  final VoidCallback onAddHabit;
  final VoidCallback onAddJournal;
  final VoidCallback onWallet;
  final VoidCallback onHealth;

  // DIUBAH: dari onStartFocus -> onAddTask
  final VoidCallback onAddTask;

  final VoidCallback onAddCook;

  const FabActionSheet({
    super.key,
    required this.onAddHabit,
    required this.onAddJournal,
    required this.onWallet,
    required this.onHealth,
    required this.onAddTask,
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
              // Handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),

              // DIUBAH: header "Tambah cepat" dihapus, sisakan tombol close saja
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const SizedBox(height: 6),

              // Grid Actions
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  // 1. Habit
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

                  // 2. Journal
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

                  // 3. Task (DIUBAH dari Focus)
                  _ActionTile(
                    icon: Icons.task_alt_rounded,
                    title: 'Task',
                    bg: AppColors.blue50,
                    fg: AppColors.blue400,
                    onTap: () {
                      Get.back();
                      onAddTask();
                    },
                  ),

                  // 4. Wallet
                  _ActionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Wallet',
                    bg: const Color(0xFFD1FAE5),
                    fg: AppColors.emerald500,
                    onTap: () {
                      Get.back();
                      onWallet();
                    },
                  ),

                  // 5. Health
                  _ActionTile(
                    icon: Icons.fitness_center_rounded,
                    title: 'Health',
                    bg: const Color(0xFFFEE2E2),
                    fg: const Color(0xFFEF4444),
                    onTap: () {
                      Get.back();
                      onHealth();
                    },
                  ),

                  // 6. Cook
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

              // DIUBAH: tip container dihapus
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: fg),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
