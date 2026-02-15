import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../widgets/fab_action_sheet.dart';
import '../../wallet/views/wallet_view.dart';
import '../../wallet/controllers/wallet_controller.dart';

class RootController extends GetxController {
  final tabIndex = 0.obs;

  // Pastikan 1 instance WalletController dipakai global (root + dashboard + wallet view)
  late final WalletController walletC;

  @override
  void onInit() {
    super.onInit();

    // Jangan bikin instance ganda
    if (Get.isRegistered<WalletController>()) {
      walletC = Get.find<WalletController>();
    } else {
      walletC = Get.put(WalletController(), permanent: true);
    }
  }

  void setTab(int i) => tabIndex.value = i;

  void onFab() {
    Get.bottomSheet(
      FabActionSheet(
        onAddHabit: () => Get.snackbar('Habit', 'Buka form tambah habit (next step)'),
        onAddJournal: () => Get.snackbar('Journal', 'Buka form journal (next step)'),

        // Wallet: tetap navigasi seperti punyamu, controller sudah global jadi data akan sinkron
        onWallet: () {
          Get.back();
          Get.to(() => const WalletView());
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
