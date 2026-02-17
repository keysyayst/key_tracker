import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Import ProfileController
import '../../profile/controllers/profile_controller.dart';
// Import Widget Mascot untuk akses Enum CatMood
import '../../../widgets/cute_cat_mascot.dart';

// Ambil WalletController yang sudah ada
import '../../wallet/controllers/wallet_controller.dart';

// Cook
import '../../cook/controllers/cook_controller.dart';

class Task {
  final String id;
  final String title;
  final String category;
  final bool completed;
  final IconData icon;
  final DateTime date;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.completed,
    required this.icon,
    required this.date,
  });

  Task copyWith({bool? completed}) {
    return Task(
      id: id,
      title: title,
      category: category,
      completed: completed ?? this.completed,
      icon: icon,
      date: date,
    );
  }
}

class DashboardController extends GetxController {
  // === INTEGRASI PROFILE ===
  late final ProfileController profileC;

  // === INTEGRASI WALLET (REAL TIME) ===
  late final WalletController walletC;

  // === INTEGRASI COOK (REAL TIME) ===
  late final CookController cookC;

  // === STATE UMUM ===
  final today = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final sectionIndex = 0.obs;
  late PageController sectionPageController;

  // === FITUR MOOD ===
  var currentMood = CatMood.happy.obs;
  var moodMessage = "Semangat hari ini ya! ✨".obs;

  // === DATA DUMMY (Tasks) ===
  final tasks = <Task>[
    Task(
      id: '1',
      title: 'Minum Air 2L',
      category: 'Health',
      completed: false,
      icon: Icons.local_drink_rounded,
      date: DateTime.now(),
    ),
    Task(
      id: '2',
      title: 'Belajar GetX',
      category: 'Skill',
      completed: true,
      icon: Icons.code_rounded,
      date: DateTime.now(),
    ),
    Task(
      id: '3',
      title: 'Beresin Kamar',
      category: 'Home',
      completed: false,
      icon: Icons.cleaning_services_rounded,
      date: DateTime.now(),
    ),
  ].obs;

  // === WALLET DI DASHBOARD (DI-SYNC DARI WalletController) ===
  final totalSaldo = 0.obs;
  final weeklyBudgetRemaining = 0.obs;
  final danaDarurat = 0.obs;

  final monthlyBudgetRemaining = 1200000.obs;
  final tabungan = 0.obs;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void onInit() {
    super.onInit();

    profileC = Get.find<ProfileController>();

    // Wallet
    if (!Get.isRegistered<WalletController>()) {
      Get.put(WalletController(), permanent: true);
    }
    walletC = Get.find<WalletController>();

    // Cook (pastikan 1 instance global)
    if (!Get.isRegistered<CookController>()) {
      Get.put(CookController(), permanent: true);
    }
    cookC = Get.find<CookController>();

    sectionPageController = PageController(initialPage: sectionIndex.value);

    _syncWalletNumbers();

    ever(walletC.wallets, (_) => _syncWalletNumbers());
    ever(walletC.weeklyBudgetLimit, (_) => _syncWalletNumbers());
    ever(walletC.weeklySpent, (_) => _syncWalletNumbers());
    ever(walletC.savingTargets, (_) => _syncWalletNumbers());
    ever(walletC.emergencyFundAmount, (_) => _syncWalletNumbers());

    // Sinkron tanggal dashboard -> Cook
    ever<DateTime>(selectedDate, (d) {
      cookC.pickCustomDate(_dateOnly(d));
    });

    cookC.pickCustomDate(_dateOnly(selectedDate.value));
  }

  @override
  void onClose() {
    sectionPageController.dispose();
    super.onClose();
  }

  void _syncWalletNumbers() {
    totalSaldo.value = walletC.totalBalance.toInt();

    final remaining = walletC.weeklyBudgetLimit.value - walletC.weeklySpent.value;
    weeklyBudgetRemaining.value = remaining > 0 ? remaining.toInt() : 0;

    danaDarurat.value = walletC.emergencyFundAmount.value.toInt();

    final savingSum = walletC.savingTargets.fold<double>(0.0, (sum, t) => sum + t.currentAmount);
    tabungan.value = savingSum.toInt();
  }

  void setMood(CatMood mood) {
    currentMood.value = mood;

    switch (mood) {
      case CatMood.sad:
        moodMessage.value = "Gapapa sedih, tarik napas dulu ya 🍃";
        break;
      case CatMood.tired:
        moodMessage.value = "Istirahat itu produktif juga kok 💤";
        break;
      case CatMood.excited:
        moodMessage.value = "Gaspol! Energi kamu keren banget 🔥";
        break;
      case CatMood.neutral:
        moodMessage.value = "Keep calm and stay cute 🐱";
        break;
      case CatMood.happy:
      default:
        moodMessage.value = "Senyum kamu nular loh! 😊";
        break;
    }
  }

  void pickDate(DateTime date) {
    selectedDate.value = _dateOnly(date);
  }

  void setSection(int index) {
    if (index == sectionIndex.value) return;
    sectionIndex.value = index;
    sectionPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
    );
  }

  void onSectionPageChanged(int index) {
    sectionIndex.value = index;
  }

  List<Task> get tasksForSelectedDate {
    return tasks.where((t) {
      final d = t.date;
      final s = selectedDate.value;
      return d.year == s.year && d.month == s.month && d.day == s.day;
    }).toList();
  }

  int get progressPercentage {
    final todayTasks = tasksForSelectedDate;
    if (todayTasks.isEmpty) return 0;
    final done = todayTasks.where((t) => t.completed).length;
    return ((done / todayTasks.length) * 100).toInt();
  }

  void toggleTask(String id) {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(completed: !tasks[index].completed);
      tasks.refresh();
    }
  }
}
