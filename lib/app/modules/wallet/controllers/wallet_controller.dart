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
      colorValue: json['color_value'] ?? 0xFFFB7185,
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

  // Dana Darurat
  final emergencyFundAmount = 0.0.obs;

  // Tab (0=Wallet, 1=Analisis)
  var currentTab = 0.obs;

  // Filter Analisis (0=Mingguan, 1=Bulanan)
  var chartFilter = 0.obs;

  /// IMPORTANT: Anchor terpisah
  final weeklyAnchorDate = DateTime.now().obs;
  final monthlyAnchorDate = DateTime.now().obs;

  var isLoading = true.obs;
  var isSubmitting = false.obs;

  // Sync root/dashboard
  final RxnString activeWalletId = RxnString();

  WalletModel? get activeWallet {
    final id = activeWalletId.value;
    if (id == null || id.isEmpty) return null;
    try {
      return wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  void setActiveWallet(String walletId) {
    activeWalletId.value = walletId;
  }

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

      final walletData = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      wallets.value = (walletData as List).map((e) => WalletModel.fromJson(e)).toList();

      if (wallets.isEmpty) {
        activeWalletId.value = null;
      } else {
        final currentId = activeWalletId.value;
        final stillExists = currentId != null && wallets.any((w) => w.id == currentId);
        if (!stillExists) activeWalletId.value = wallets.first.id;
      }

      final transactionData = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      transactions.value =
          (transactionData as List).map((e) => TransactionModel.fromJson(e)).toList();

      final budgetData =
          await _supabase.from('budgets').select().eq('user_id', userId).maybeSingle();
      weeklyBudgetLimit.value =
          budgetData == null ? 0.0 : (budgetData['weekly_limit'] as num).toDouble();

      calculateWeeklySpent();

      final savingData = await _supabase
          .from('saving_targets')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      savingTargets.value =
          (savingData as List).map((e) => SavingTargetModel.fromJson(e)).toList();

      try {
        final ef = await _supabase
            .from('emergency_fund')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        emergencyFundAmount.value = ef == null ? 0.0 : (ef['amount'] as num).toDouble();
      } catch (_) {
        emergencyFundAmount.value = 0.0;
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void calculateWeeklySpent() {
    final now = DateTime.now();
    final startOfWeek =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    double spent = 0;
    for (var trx in transactions) {
      final inRange =
          (trx.date.isAtSameMomentAs(startOfWeek) || trx.date.isAfter(startOfWeek)) &&
              trx.date.isBefore(startOfNextWeek);
      if (trx.isExpense && inRange) spent += trx.amount;
    }
    weeklySpent.value = spent;
  }

  // ====== ANALISIS: helper anchor ======
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get currentAnchorDate {
    return chartFilter.value == 0 ? weeklyAnchorDate.value : monthlyAnchorDate.value;
  }

  void setChartFilter(int value) {
    chartFilter.value = value;
    // Jangan mengubah anchor lain.
  }

  void setWeeklyAnchorDate(DateTime d) {
    weeklyAnchorDate.value = _startOfDay(d);
  }

  void setMonthlyAnchorDate(DateTime d) {
    monthlyAnchorDate.value = _startOfDay(d);
  }

  void setCurrentAnchorDate(DateTime d) {
    if (chartFilter.value == 0) {
      setWeeklyAnchorDate(d);
    } else {
      setMonthlyAnchorDate(d);
    }
  }

  DateTimeRange get analysisRange {
    final anchor = _startOfDay(currentAnchorDate);

    if (chartFilter.value == 0) {
      final start = anchor.subtract(Duration(days: anchor.weekday - 1));
      final end = start.add(const Duration(days: 7)); // exclusive
      return DateTimeRange(start: start, end: end);
    } else {
      final start = DateTime(anchor.year, anchor.month, 1);
      final end = (anchor.month == 12)
          ? DateTime(anchor.year + 1, 1, 1)
          : DateTime(anchor.year, anchor.month + 1, 1);
      return DateTimeRange(start: start, end: end);
    }
  }

  String get analysisRangeLabel {
    final r = analysisRange;
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    final endInclusive = r.end.subtract(const Duration(days: 1));
    return '${fmt.format(r.start)} - ${fmt.format(endInclusive)}';
  }

  String get currentAnchorLabel {
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    return fmt.format(currentAnchorDate);
  }

  // --- PIE DATA ---
  List<PieChartData> getPieData({required bool isExpense}) {
    final Map<String, double> groupedData = {};
    final range = analysisRange;

    for (final trx in transactions) {
      final inRange = (trx.date.isAtSameMomentAs(range.start) || trx.date.isAfter(range.start)) &&
          trx.date.isBefore(range.end);

      if (trx.isExpense == isExpense && inRange) {
        groupedData[trx.title] = (groupedData[trx.title] ?? 0) + trx.amount;
      }
    }

    final List<Color> colors = [
      const Color(0xFFFB7185),
      const Color(0xFFF472B6),
      const Color(0xFFFB923C),
      const Color(0xFF34D399),
      const Color(0xFF60A5FA),
      const Color(0xFFA78BFA),
    ];

    int colorIndex = 0;
    final List<PieChartData> result = [];
    groupedData.forEach((key, value) {
      result.add(PieChartData(key, value, colors[colorIndex % colors.length]));
      colorIndex++;
    });

    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  // ====== Dana Darurat ======
  Future<void> addEmergencyFund(double amount) async {
    if (amount <= 0) {
      Get.snackbar("Oops", "Nominal harus lebih dari 0",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final userId = _supabase.auth.currentUser!.id;
      final newAmount = emergencyFundAmount.value + amount;

      await _supabase.from('emergency_fund').upsert({'user_id': userId, 'amount': newAmount});
      emergencyFundAmount.value = newAmount;

      Get.snackbar("Siap", "Dana darurat bertambah",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah dana darurat",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> reduceEmergencyFund(double amount) async {
    if (amount <= 0) {
      Get.snackbar("Oops", "Nominal harus lebih dari 0",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (amount > emergencyFundAmount.value) {
      Get.snackbar("Oops", "Dana darurat tidak cukup",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final userId = _supabase.auth.currentUser!.id;
      final newAmount = emergencyFundAmount.value - amount;

      await _supabase.from('emergency_fund').upsert({'user_id': userId, 'amount': newAmount});
      emergencyFundAmount.value = newAmount;

      Get.snackbar("Oke", "Dana darurat berkurang",
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal mengurangi dana darurat",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  // --- ACTIONS WALLET/SAVING/TRANSAKSI (tetap sama) ---
  Future<void> addWallet(String name, double balance) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _supabase.from('wallets').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'name': name,
        'balance': balance,
        'icon_code': Icons.account_balance_wallet_rounded.codePoint,
        'color_value': 0xFFFB7185,
      });
      await fetchData();
      Get.snackbar("Berhasil", "Dompet ditambahkan",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah wallet",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> editWallet(String id, String newName) async {
    try {
      await _supabase.from('wallets').update({'name': newName}).eq('id', id);
      await fetchData();
      Get.snackbar("Update", "Nama dompet diubah",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal update wallet",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteWallet(String id) async {
    try {
      await _supabase.from('wallets').delete().eq('id', id);
      wallets.removeWhere((w) => w.id == id);
      await fetchData();
      Get.snackbar("Dihapus", "Dompet dihapus",
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Gagal", "Error menghapus dompet",
          backgroundColor: Colors.red, colorText: Colors.white);
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

      Get.snackbar("Sukses", "Transaksi dicatat",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal catat transaksi",
          backgroundColor: Colors.red, colorText: Colors.white);
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
      Get.snackbar("Siap", "Budget dialokasikan",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal set budget",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> addSavingTarget(String title, double target) async {
    try {
      await _supabase.from('saving_targets').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'title': title,
        'target_amount': target,
        'current_amount': 0,
      });
      await fetchData();
      Get.snackbar("Semangat", "Wishlist baru dimulai!",
          backgroundColor: Colors.pink, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal tambah wishlist",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateSavingAmount(String id, double amountToAdd) async {
    try {
      final target = savingTargets.firstWhere((t) => t.id == id);
      final newAmount = target.currentAmount + amountToAdd;

      await _supabase.from('saving_targets').update({'current_amount': newAmount}).eq('id', id);
      await fetchData();
      Get.snackbar("Yay!", "Wishlist bertambah Rp ${amountToAdd.toInt()}",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal update wishlist",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> editSavingTarget(String id, String newTitle, double newTarget) async {
    try {
      await _supabase.from('saving_targets').update({'title': newTitle, 'target_amount': newTarget}).eq('id', id);
      await fetchData();
      Get.snackbar("Update", "Info wishlist diubah",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal edit wishlist",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteSavingTarget(String id) async {
    try {
      await _supabase.from('saving_targets').delete().eq('id', id);
      savingTargets.removeWhere((t) => t.id == id);
      Get.snackbar("Dihapus", "Wishlist dihapus",
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal hapus wishlist",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
