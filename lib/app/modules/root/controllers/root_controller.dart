import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../widgets/fab_action_sheet.dart';

class RootController extends GetxController {
  final tabIndex = 0.obs;

  void setTab(int i) => tabIndex.value = i;

  void onFab() {
    Get.bottomSheet(
      FabActionSheet(
        onAddHabit: () => Get.snackbar('Habit', 'Buka form tambah habit (next step)'),
        onAddJournal: () => Get.snackbar('Journal', 'Buka form journal (next step)'),
        onAddIncome: () => Get.snackbar('Income', 'Buka form income (next step)'),
        onAddExpense: () => Get.snackbar('Expense', 'Buka form expense (next step)'),
        onStartFocus: () => Get.snackbar('Focus', 'Mulai focus timer (next step)'),
        onAddCook: () => Get.snackbar('Cook', 'Buka form tambah resep masakan (next step)'),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
