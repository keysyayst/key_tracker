import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Import ProfileController
import '../../profile/controllers/profile_controller.dart'; 
// Import Widget Mascot untuk akses Enum CatMood
import '../../../widgets/cute_cat_mascot.dart';

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
  final profileC = Get.find<ProfileController>();

  // === STATE UMUM ===
  final today = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final sectionIndex = 0.obs;
  late PageController sectionPageController;

  // === FITUR MOOD (BARU) ===
  var currentMood = CatMood.happy.obs; // Default Happy
  var moodMessage = "Semangat hari ini ya! ✨".obs;

  // === DATA DUMMY (Tasks & Wallet) ===
  final tasks = <Task>[
    Task(id: '1', title: 'Minum Air 2L', category: 'Health', completed: false, icon: Icons.local_drink_rounded, date: DateTime.now()),
    Task(id: '2', title: 'Belajar GetX', category: 'Skill', completed: true, icon: Icons.code_rounded, date: DateTime.now()),
    Task(id: '3', title: 'Beresin Kamar', category: 'Home', completed: false, icon: Icons.cleaning_services_rounded, date: DateTime.now()),
  ].obs;

  final weeklyBudgetRemaining = 250000.obs;
  final monthlyBudgetRemaining = 1200000.obs;
  final totalSaldo = 4500000.obs;
  final tabungan = 10000000.obs;

  // === FITUR JOURNAL ===
  var journalEntries = <DateTime, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    sectionPageController = PageController(initialPage: sectionIndex.value);
  }

  @override
  void onClose() {
    sectionPageController.dispose();
    super.onClose();
  }

  // === LOGIKA MOOD (BARU) ===
  void setMood(CatMood mood) {
    currentMood.value = mood;
    
    // Ganti Pesan Motivasi sesuai Mood
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
