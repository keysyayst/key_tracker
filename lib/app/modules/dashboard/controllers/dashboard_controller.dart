import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Import ProfileController
import '../../profile/controllers/profile_controller.dart';
// Import Widget Mascot untuk akses Enum CatMood
import '../../../widgets/cute_cat_mascot.dart';

// Ambil WalletController yang sudah ada
import '../../wallet/controllers/wallet_controller.dart';

// Model sederhana untuk Task
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
  // (yang kepakai untuk 3 urutan kamu)
  final totalSaldo = 0.obs;
  final weeklyBudgetRemaining = 0.obs; // SISA (bukan total)
  final danaDarurat = 0.obs;

  // yang lain (kalau masih dipakai di panel lain, biarkan aman)
  final monthlyBudgetRemaining = 1200000.obs; // tidak ada sumber di WalletController
  final tabungan = 0.obs; // kalau sudah tidak dipakai di view, boleh kamu hapus

  // === FITUR JOURNAL ===
  var journalEntries = <DateTime, String>{}.obs;

  @override
  void onInit() {
    super.onInit();

    profileC = Get.find<ProfileController>();

    // Pastikan WalletController ada sebelum dipakai
    if (!Get.isRegistered<WalletController>()) {
      Get.put(WalletController(), permanent: true);
    }
    walletC = Get.find<WalletController>();

    sectionPageController = PageController(initialPage: sectionIndex.value);

    _syncWalletNumbers();

    ever(walletC.wallets, (_) => _syncWalletNumbers());
    ever(walletC.weeklyBudgetLimit, (_) => _syncWalletNumbers());
    ever(walletC.weeklySpent, (_) => _syncWalletNumbers());
    ever(walletC.savingTargets, (_) => _syncWalletNumbers());

    // Dana darurat realtime (kalau field ini ada di WalletController kamu)
    ever(walletC.emergencyFundAmount, (_) => _syncWalletNumbers());
  }

  @override
  void onClose() {
    sectionPageController.dispose();
    super.onClose();
  }

  void _syncWalletNumbers() {
    // 1) Total saldo = total balance semua wallet
    totalSaldo.value = walletC.totalBalance.toInt();

    // 2) Sisa budget mingguan = weeklyLimit - weeklySpent (min 0)
    final remaining = walletC.weeklyBudgetLimit.value - walletC.weeklySpent.value;
    weeklyBudgetRemaining.value = remaining > 0 ? remaining.toInt() : 0;

    // 3) Dana darurat
    danaDarurat.value = walletC.emergencyFundAmount.value.toInt();

    // Optional: wishlist/tabungan total (kalau masih dipakai)
    final savingSum = walletC.savingTargets.fold<double>(0.0, (sum, t) => sum + t.currentAmount);
    tabungan.value = savingSum.toInt();
  }

  // === LOGIKA MOOD ===
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

  // === LOGIKA TANGGAL ===
  void pickDate(DateTime date) {
    selectedDate.value = date;
  }

  // === LOGIKA NAVIGASI SECTION ===
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

  // === LOGIKA TASKS ===
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

  // === LOGIKA JOURNAL ===
  String get currentJournalContent {
    final dateKey = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    return journalEntries[dateKey] ?? '';
  }

  void saveJournal(String content) {
    final dateKey = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );

    if (content.trim().isEmpty) {
      journalEntries.remove(dateKey);
    } else {
      journalEntries[dateKey] = content;
    }
    journalEntries.refresh();
  }
}
