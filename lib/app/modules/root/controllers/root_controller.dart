import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/fab_action_sheet.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../../wallet/views/wallet_view.dart';

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
        onAddHabit: () => Get.toNamed(Routes.HABIT),

        onAddWishlist: () {
          Get.back();
          Get.toNamed(Routes.WISHLIST);
          },
            

        onWallet: () {
          Get.back();
          Get.to(() => const WalletView());
        },

        onHealth: () {
          Get.back();
          Get.toNamed(Routes.HEALTH);
        },

        onAddTask: () {
          Get.back();
          Get.toNamed(Routes.TASK);
        },

        onAddCook: () {
          Get.back();
          Get.toNamed(Routes.COOK);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
