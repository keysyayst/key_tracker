import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../widgets/fab_action_sheet.dart';
import '../../wallet/views/wallet_view.dart'; // Pastikan import ini ada

class RootController extends GetxController {
  final tabIndex = 0.obs;

  void setTab(int i) => tabIndex.value = i;

  void onFab() {
    Get.bottomSheet(
      FabActionSheet(
        onAddHabit: () => Get.snackbar('Habit', 'Buka form tambah habit (next step)'),
        onAddJournal: () => Get.snackbar('Journal', 'Buka form journal (next step)'),
        
        // PERBAIKAN DI SINI: Ganti snackbar dengan navigasi ke WalletView
        onWallet: () {
          Get.back(); // Tutup bottom sheet dulu
          Get.to(() => const WalletView()); // Pindah ke halaman Wallet
        },
        
        onHealth: () => Get.snackbar('Health', 'Buka tracker kesehatan (next step)'),
        onStartFocus: () => Get.snackbar('Focus', 'Mulai focus timer (next step)'),
        onAddCook: () => Get.snackbar('Cook', 'Buka form resep masakan (next step)'),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
