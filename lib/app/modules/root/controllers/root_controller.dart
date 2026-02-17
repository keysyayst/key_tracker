import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/fab_action_sheet.dart';
import '../../wallet/views/wallet_view.dart';
import '../../wallet/controllers/wallet_controller.dart';

// kalau kamu sudah punya CookView, boleh import & pakai di onAddCook
// import '../../cook/views/cook_view.dart';

class RootController extends GetxController {
  final tabIndex = 0.obs;

  late final WalletController walletC;

  @override
  void onInit() {
    super.onInit();

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

        onWallet: () {
          Get.back();
          Get.to(() => const WalletView());
        },

        onHealth: () => Get.snackbar('Health', 'Buka tracker kesehatan (next step)'),

        onAddTask: () {
  Get.back();
  Get.toNamed(Routes.TASK);
},
        onAddCook: () => Get.snackbar('Cook', 'Buka form resep masakan (next step)'),
        // contoh kalau sudah pakai CookView:
        // onAddCook: () { Get.back(); Get.to(() => const CookView()); },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
