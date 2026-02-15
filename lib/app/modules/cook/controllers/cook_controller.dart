import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookDish {
  final String id;
  final DateTime cookDate; // date-only
  final String name;
  final String ingredients;
  final double budget;

  CookDish({
    required this.id,
    required this.cookDate,
    required this.name,
    required this.ingredients,
    required this.budget,
  });

  factory CookDish.fromJson(Map<String, dynamic> json) {
    final dateStr = (json['cook_date'] ?? '') as String;
    final parsed = DateTime.tryParse(dateStr) ?? DateTime.now();
    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);

    return CookDish(
      id: (json['id'] ?? '') as String,
      cookDate: dateOnly,
      name: (json['name'] ?? '') as String,
      ingredients: (json['ingredients'] ?? '') as String,
      budget: ((json['budget'] ?? 0) as num).toDouble(),
    );
  }
}

enum CookViewMode { today, upcoming3Days, customDate }

class CookController extends GetxController {
  final _supabase = Supabase.instance.client;

  final now = DateTime.now().obs;
  final mode = CookViewMode.today.obs;
  final selectedDate = DateTime.now().obs;

  final isLoading = true.obs;
  final isSubmitting = false.obs;

  final allDishes = <CookDish>[].obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  Timer? _clock;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get today => _dateOnly(now.value);

  List<DateTime> get upcomingDates {
    final t = today;
    return [
      t.add(const Duration(days: 1)),
      t.add(const Duration(days: 2)),
      t.add(const Duration(days: 3)),
    ];
  }

  bool get isTodayMode => mode.value == CookViewMode.today;
  bool get isUpcomingMode => mode.value == CookViewMode.upcoming3Days;

  @override
  void onInit() {
    super.onInit();

    selectedDate.value = _dateOnly(DateTime.now());
    mode.value = CookViewMode.today;

    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final before = _dateOnly(now.value);
      now.value = DateTime.now();
      final after = _dateOnly(now.value);

      if (before != after && mode.value == CookViewMode.today) {
        selectedDate.value = after;
      }
    });

    _startRealtime();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _clock?.cancel();
    super.onClose();
  }

  void setTodayMode() {
    mode.value = CookViewMode.today;
    selectedDate.value = today;
  }

  void setUpcomingMode() {
    mode.value = CookViewMode.upcoming3Days;
  }

  void pickCustomDate(DateTime d) {
    mode.value = CookViewMode.customDate;
    selectedDate.value = _dateOnly(d);
  }

  // ===== Data helpers =====

  List<CookDish> _dishesForDate(DateTime date) {
    final s = _dateOnly(date);
    final filtered = allDishes.where((x) => _dateOnly(x.cookDate) == s).toList();
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  List<CookDish> get dishesForSelectedDate => _dishesForDate(selectedDate.value);

  Map<DateTime, List<CookDish>> get upcomingGrouped {
    final map = <DateTime, List<CookDish>>{};
    for (final d in upcomingDates) {
      map[_dateOnly(d)] = _dishesForDate(d);
    }
    return map;
  }

  bool get isEmptyForCurrentView {
    if (isUpcomingMode) return upcomingGrouped.values.every((list) => list.isEmpty);
    return dishesForSelectedDate.isEmpty;
  }

  DateTime get defaultFormDate {
    if (isUpcomingMode) return upcomingDates.first;
    if (isTodayMode) return today;
    return selectedDate.value;
  }

  // ===== Realtime stream (opsional, tetap dipakai jika Supabase Realtime aktif) =====

  Future<void> _startRealtime() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    _sub = _supabase
        .from('cook_dishes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('cook_date')
        .order('created_at')
        .listen((rows) {
      allDishes.value = rows.map(CookDish.fromJson).toList();
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
    });
  }

  // ===== Local upsert helper =====

  void _upsertLocal(CookDish dish) {
    final idx = allDishes.indexWhere((d) => d.id == dish.id);
    if (idx == -1) {
      allDishes.add(dish);
    } else {
      allDishes[idx] = dish;
    }
    allDishes.refresh();
  }

  // ===== CRUD (return null = sukses, string = error message) =====

  Future<String?> addDish({
    required DateTime cookDate,
    required String name,
    required String ingredients,
    required double budget,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nama masakan tidak boleh kosong.';
    final safeBudget = budget.isNaN || budget.isInfinite ? 0.0 : budget;
    if (safeBudget < 0) return 'Budget tidak boleh minus.';

    if (isSubmitting.value) return 'Sedang menyimpan...';
    isSubmitting.value = true;

    try {
      final row = await _supabase
          .from('cook_dishes')
          .insert({
            'user_id': user.id,
            'cook_date': _dateOnly(cookDate).toIso8601String().substring(0, 10),
            'name': trimmed,
            'ingredients': ingredients.trim(),
            'budget': safeBudget,
          })
          .select()
          .single();

      _upsertLocal(CookDish.fromJson(row));
      return null;
    } catch (_) {
      return 'Gagal menambah masakan.';
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> updateDish({
    required String id,
    required DateTime cookDate,
    required String name,
    required String ingredients,
    required double budget,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nama masakan tidak boleh kosong.';
    final safeBudget = budget.isNaN || budget.isInfinite ? 0.0 : budget;
    if (safeBudget < 0) return 'Budget tidak boleh minus.';

    if (isSubmitting.value) return 'Sedang menyimpan...';
    isSubmitting.value = true;

    try {
      final row = await _supabase
          .from('cook_dishes')
          .update({
            'cook_date': _dateOnly(cookDate).toIso8601String().substring(0, 10),
            'name': trimmed,
            'ingredients': ingredients.trim(),
            'budget': safeBudget,
          })
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();

      _upsertLocal(CookDish.fromJson(row));
      return null;
    } catch (_) {
      return 'Gagal menyimpan perubahan.';
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> deleteDish(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    try {
      await _supabase.from('cook_dishes').delete().eq('id', id).eq('user_id', user.id);
      allDishes.removeWhere((d) => d.id == id);
      allDishes.refresh();
      return null;
    } catch (_) {
      return 'Gagal menghapus.';
    }
  }
}
