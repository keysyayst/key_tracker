import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// --- MODELS ---
class WalletModel {
  final String id;
  final String name;
  final double balance;
  final int iconCode;
  final int colorValue;

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.iconCode,
    required this.colorValue,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
      iconCode: json['icon_code'] ?? 58946, 
      colorValue: json['color_value'] ?? 0xFFFB7185, // Default Pink
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String walletId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.walletId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      isExpense: json['is_expense'],
      date: DateTime.parse(json['date']),
      walletId: json['wallet_id'] ?? '',
    );
  }
}

class SavingTargetModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;

  SavingTargetModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
  });

  factory SavingTargetModel.fromJson(Map<String, dynamic> json) {
    return SavingTargetModel(
      id: json['id'],
      title: json['title'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
    );
  }
}

class PieChartData {
  final String label;
  final double value;
  final Color color;
  PieChartData(this.label, this.value, this.color);
}

// --- CONTROLLER ---

class WalletController extends GetxController {
  final _supabase = Supabase.instance.client;

  var wallets = <WalletModel>[].obs;
  var transactions = <TransactionModel>[].obs;
  var savingTargets = <SavingTargetModel>[].obs;
  var weeklyBudgetLimit = 0.0.obs;
  var weeklySpent = 0.0.obs;
  
  // State untuk Tab (0 = Wallet, 1 = Grafik)
  var currentTab = 0.obs;
  
  // State Filter Grafik (0 = Mingguan, 1 = Bulanan)
  var chartFilter = 0.obs;

  var isLoading = true.obs;
  var isSubmitting = false.obs;

  double get totalBalance => wallets.fold(0, (sum, item) => sum + item.balance);

  @override
  void onInit() {
    super.onInit();
    if (_supabase.auth.currentUser != null) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Wallets
      final walletData = await _supabase.from('wallets').select().eq('user_id', userId).order('created_at');
      wallets.value = (walletData as List).map((e) => WalletModel.fromJson(e)).toList();

      // Transactions
      final transactionData = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      transactions.value = (transactionData as List).map((e) => TransactionModel.fromJson(e)).toList();

      // Budget
      final budgetData = await _supabase.from('budgets').select().eq('user_id', userId).maybeSingle();
      if (budgetData != null) {
        weeklyBudgetLimit.value = (budgetData['weekly_limit'] as num).toDouble();
      } else {
        weeklyBudgetLimit.value = 0.0;
      }

      calculateWeeklySpent();

      // Savings
      final savingData = await _supabase.from('saving_targets').select().eq('user_id', userId).order('created_at');
      savingTargets.value = (savingData as List).map((e) => SavingTargetModel.fromJson(e)).toList();

    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void calculateWeeklySpent() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    double spent = 0;
    for (var trx in transactions) {
      if (trx.isExpense && trx.date.isAfter(startOfWeek) && trx.date.isBefore(startOfNextWeek)) {
        spent += trx.amount;
      }
    }
    weeklySpent.value = spent;
  }

  // --- ACTIONS ---

  Future<void> addWallet(String name, double balance) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _supabase.from('wallets').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'name': name,
        'balance': balance,
        'icon_code': Icons.account_balance_wallet_rounded.codePoint,
        'color_value': 0xFFFB7185, // Pink
      });
      await fetchData();
      Get.snackbar("Berhasil", "Dompet ditambahkan", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah wallet", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> editWallet(String id, String newName) async {
    try {
      await _supabase.from('wallets').update({'name': newName}).eq('id', id);
      await fetchData();
      Get.snackbar("Update", "Nama dompet diubah", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal update wallet", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteWallet(String id) async {
    try {
      await _supabase.from('wallets').delete().eq('id', id);
      wallets.removeWhere((w) => w.id == id);
      await fetchData(); 
      Get.snackbar("Dihapus", "Dompet dihapus", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Gagal", "Error menghapus dompet", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> addTransaction(String title, double amount, bool isExpense, String walletId) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'wallet_id': walletId,
        'title': title,
        'amount': amount,
        'is_expense': isExpense,
        'date': DateTime.now().toIso8601String(),
      });
      
      final walletIndex = wallets.indexWhere((w) => w.id == walletId);
      if (walletIndex != -1) {
        final oldWallet = wallets[walletIndex];
        final newBalance = isExpense ? oldWallet.balance - amount : oldWallet.balance + amount;
        await _supabase.from('wallets').update({'balance': newBalance}).eq('id', walletId);
      }
      if (isExpense) weeklySpent.value += amount;
      await fetchData();
      Get.snackbar("Sukses", "Transaksi dicatat", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal catat transaksi", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> setBudgetWithAllocation(double amount, String sourceWalletId) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final existing = await _supabase.from('budgets').select().eq('user_id', userId).maybeSingle();
      if (existing != null) {
        await _supabase.from('budgets').update({'weekly_limit': amount}).eq('user_id', userId);
      } else {
        await _supabase.from('budgets').insert({'user_id': userId, 'weekly_limit': amount});
      }

      await _supabase.from('transactions').insert({
        'user_id': userId,
        'wallet_id': sourceWalletId,
        'title': "Alokasi Budget Mingguan",
        'amount': amount,
        'is_expense': true,
        'date': DateTime.now().toIso8601String(),
      });

      final wallet = wallets.firstWhere((w) => w.id == sourceWalletId);
      await _supabase.from('wallets').update({'balance': wallet.balance - amount}).eq('id', sourceWalletId);

      weeklyBudgetLimit.value = amount;
      await fetchData();
      Get.snackbar("Siap", "Budget dialokasikan", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal set budget", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // --- ACTIONS: SAVING TARGETS ---

  Future<void> addSavingTarget(String title, double target) async {
    try {
      await _supabase.from('saving_targets').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'title': title,
        'target_amount': target,
        'current_amount': 0,
      });
      await fetchData();
      Get.snackbar("Semangat", "Impian baru dimulai!", backgroundColor: Colors.pink, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal tambah impian", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateSavingAmount(String id, double amountToAdd) async {
    try {
      final target = savingTargets.firstWhere((t) => t.id == id);
      final newAmount = target.currentAmount + amountToAdd;
      
      await _supabase.from('saving_targets').update({'current_amount': newAmount}).eq('id', id);
      await fetchData();
      Get.snackbar("Yay!", "Tabungan bertambah Rp ${amountToAdd.toInt()}", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal update tabungan", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> editSavingTarget(String id, String newTitle, double newTarget) async {
    try {
      await _supabase.from('saving_targets').update({
        'title': newTitle,
        'target_amount': newTarget
      }).eq('id', id);
      await fetchData();
      Get.snackbar("Update", "Info impian diubah", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal edit impian", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteSavingTarget(String id) async {
    try {
      await _supabase.from('saving_targets').delete().eq('id', id);
      savingTargets.removeWhere((t) => t.id == id);
      Get.snackbar("Dihapus", "Impian dihapus", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal hapus impian", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- PIE CHART DATA GENERATION ---
  // Mengelompokkan transaksi berdasarkan Judul/Kategori untuk Pie Chart
  List<PieChartData> getPieData({required bool isExpense}) {
    Map<String, double> groupedData = {};

    final now = DateTime.now();
    // Filter rentang waktu
    final startDate = chartFilter.value == 0 
        ? now.subtract(const Duration(days: 7)) // Mingguan
        : DateTime(now.year, now.month - 1, now.day); // Bulanan (approx 30 days)

    for (var trx in transactions) {
      if (trx.isExpense == isExpense && trx.date.isAfter(startDate)) {
        // Gunakan Title sebagai kategori. Jika ada sistem kategori, ganti trx.title dengan trx.category
        if (groupedData.containsKey(trx.title)) {
          groupedData[trx.title] = groupedData[trx.title]! + trx.amount;
        } else {
          groupedData[trx.title] = trx.amount;
        }
      }
    }

    // Convert Map ke List PieChartData dengan warna unik
    List<Color> colors = [
      const Color(0xFFFB7185), // Pink
      const Color(0xFFF472B6), // Light Pink
      const Color(0xFFFB923C), // Orange
      const Color(0xFF34D399), // Emerald
      const Color(0xFF60A5FA), // Blue
      const Color(0xFFA78BFA), // Lavender
    ];

    int colorIndex = 0;
    List<PieChartData> result = [];
    groupedData.forEach((key, value) {
      result.add(PieChartData(key, value, colors[colorIndex % colors.length]));
      colorIndex++;
    });

    // Sort biar yang gede di awal
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }
}
