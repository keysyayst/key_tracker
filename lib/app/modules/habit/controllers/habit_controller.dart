import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitCategoryItem {
  final String id;
  final String name;
  final String slug;
  final String iconKey;
  final String colorKey;

  HabitCategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
    required this.colorKey,
  });

  factory HabitCategoryItem.fromJson(Map<String, dynamic> json) {
    return HabitCategoryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      iconKey: (json['icon_key'] ?? 'sparkle').toString(),
      colorKey: (json['color_key'] ?? 'pink').toString(),
    );
  }
}

class Habit {
  final String id;
  final String title;
  final String categoryId;
  final String iconKey;
  final String colorKey;
  final DateTime startDate;
  final DateTime? endDate;
  final int daysMask;
  final bool isActive;

  Habit({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.iconKey,
    required this.colorKey,
    required this.startDate,
    required this.endDate,
    required this.daysMask,
    required this.isActive,
  });

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory Habit.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return _dateOnly(DateTime.now());
      if (v is DateTime) return _dateOnly(v);
      final dt = DateTime.tryParse(v.toString());
      return _dateOnly(dt ?? DateTime.now());
    }

    return Habit(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      categoryId: (json['category_id'] ?? '').toString(),
      iconKey: (json['icon_key'] ?? 'sparkle').toString(),
      colorKey: (json['color_key'] ?? 'pink').toString(),
      startDate: parseDate(json['start_date']),
      endDate: json['end_date'] == null ? null : parseDate(json['end_date']),
      daysMask: (json['days_mask'] ?? 127) as int,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime logDate;
  final bool done;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.done,
  });

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return _dateOnly(DateTime.now());
      if (v is DateTime) return _dateOnly(v);
      final dt = DateTime.tryParse(v.toString());
      return _dateOnly(dt ?? DateTime.now());
    }

    return HabitLog(
      id: (json['id'] ?? '').toString(),
      habitId: (json['habit_id'] ?? '').toString(),
      logDate: parseDate(json['log_date']),
      done: (json['done'] ?? true) as bool,
    );
  }
}

class HabitController extends GetxController {
  final supabase = Supabase.instance.client;

  final isLoading = true.obs;
  final isSubmitting = false.obs;

  final selectedDate = DateTime.now().obs;

  final habits = <Habit>[].obs;
  final logs = <HabitLog>[].obs;

  final categories = <HabitCategoryItem>[].obs;
  final isCatLoading = true.obs;

  // Debug: biar kamu bisa lihat semua habit tanpa filter tanggal
  final showAllHabits = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _habitsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _logsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _catSub;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _isoDate(DateTime d) {
    final x = _dateOnly(d);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$mm-$dd';
  }

  @override
  void onInit() {
    super.onInit();
    selectedDate.value = _dateOnly(DateTime.now());
    _startStreams();
  }

  @override
  void onClose() {
    _habitsSub?.cancel();
    _logsSub?.cancel();
    _catSub?.cancel();
    super.onClose();
  }

  void pickDate(DateTime d) => selectedDate.value = _dateOnly(d);

  int _weekdayIndex(DateTime date) => (date.weekday - 1) % 7;

  bool _maskAllows(int mask, DateTime date) {
    final idx = _weekdayIndex(date);
    return (mask & (1 << idx)) != 0;
  }

  bool isHabitScheduledOn(Habit h, DateTime date) {
    final d = _dateOnly(date);
    if (!h.isActive) return false;
    if (d.isBefore(h.startDate)) return false;
    if (h.endDate != null && d.isAfter(h.endDate!)) return false;
    return _maskAllows(h.daysMask, d);
  }

  List<Habit> get habitsForSelectedDate {
    final d = selectedDate.value;
    final list = habits.where((h) => isHabitScheduledOn(h, d)).toList();
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  bool isDoneForDate(String habitId, DateTime date) {
    final d = _dateOnly(date);
    final found = logs.firstWhereOrNull((l) => l.habitId == habitId && l.logDate == d);
    return found?.done ?? false;
  }

  HabitCategoryItem? categoryById(String id) =>
      categories.firstWhereOrNull((c) => c.id == id);

  Future<void> _startStreams() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      isCatLoading.value = false;
      return;
    }

    isLoading.value = true;
    isCatLoading.value = true;

    await _habitsSub?.cancel();
    await _logsSub?.cancel();
    await _catSub?.cancel();

    _catSub = supabase
        .from('habit_categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((rows) {
      categories.value = rows.map(HabitCategoryItem.fromJson).toList();
      isCatLoading.value = false;
    }, onError: (_) {
      isCatLoading.value = false;
    });

    _habitsSub = supabase
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((rows) {
      habits.value = rows.map(Habit.fromJson).toList();
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
    });

    _logsSub = supabase
        .from('habit_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .listen((rows) {
      logs.value = rows.map(HabitLog.fromJson).toList();
    });
  }

  // fallback manual refresh (kalau realtime belum aktif)
  Future<void> refreshNow() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final hRows = await supabase
        .from('habits')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    habits.value = (hRows as List).cast<Map<String, dynamic>>().map(Habit.fromJson).toList();

    final lRows = await supabase
        .from('habit_logs')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    logs.value = (lRows as List).cast<Map<String, dynamic>>().map(HabitLog.fromJson).toList();

    final cRows = await supabase
        .from('habit_categories')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    categories.value = (cRows as List).cast<Map<String, dynamic>>().map(HabitCategoryItem.fromJson).toList();
  }

  static int maskEveryday() => 127;

  static int maskFromWeekdays(Set<int> weekdaysMon1toSun7) {
    int mask = 0;
    for (final wd in weekdaysMon1toSun7) {
      final idx = (wd - 1) % 7;
      mask |= (1 << idx);
    }
    return mask;
  }

  String _slugify(String s) {
    final x = s.trim().toLowerCase();
    final y = x.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    final z = y.replaceAll(RegExp(r'\s+'), '-');
    final w = z.replaceAll(RegExp(r'-+'), '-');
    return w.isEmpty ? 'other' : w;
  }

  Future<String?> createCategory({
    required String name,
    required String iconKey,
    required String colorKey,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final n = name.trim();
    if (n.isEmpty) return 'Nama kategori tidak boleh kosong.';
    if (isSubmitting.value) return 'Sedang menyimpan...';

    isSubmitting.value = true;
    try {
      await supabase.from('habit_categories').insert({
        'user_id': user.id,
        'name': n,
        'slug': _slugify(n),
        'icon_key': iconKey,
        'color_key': colorKey,
      });

      await refreshNow();
      return null;
    } on PostgrestException catch (e) {
      return '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.trim();
    } catch (e) {
      return e.toString();
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> createHabit({
    required String title,
    required String categoryId,
    required String iconKey,
    required String colorKey,
    required DateTime startDate,
    required DateTime? endDate,
    required int daysMask,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final t = title.trim();
    if (t.isEmpty) return 'Nama habit tidak boleh kosong.';
    if (endDate != null && _dateOnly(endDate).isBefore(_dateOnly(startDate))) {
      return 'Tanggal akhir tidak boleh sebelum tanggal mulai.';
    }
    if (isSubmitting.value) return 'Sedang menyimpan...';

    isSubmitting.value = true;
    try {
      await supabase.from('habits').insert({
        'user_id': user.id,
        'title': t,
        'category_id': categoryId,
        'period': 'daily', // FIX period NOT NULL
        'icon_key': iconKey,
        'color_key': colorKey,
        'start_date': _isoDate(startDate),
        'end_date': endDate == null ? null : _isoDate(endDate),
        'days_mask': daysMask,
        'is_active': true,
      });

      await refreshNow();
      return null;
    } on PostgrestException catch (e) {
      return '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.trim();
    } catch (e) {
      return e.toString();
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> updateHabit({
    required String id,
    required String title,
    required String categoryId,
    required String iconKey,
    required String colorKey,
    required DateTime startDate,
    required DateTime? endDate,
    required int daysMask,
    required bool isActive,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final t = title.trim();
    if (t.isEmpty) return 'Nama habit tidak boleh kosong.';
    if (endDate != null && _dateOnly(endDate).isBefore(_dateOnly(startDate))) {
      return 'Tanggal akhir tidak boleh sebelum tanggal mulai.';
    }
    if (isSubmitting.value) return 'Sedang menyimpan...';

    isSubmitting.value = true;
    try {
      await supabase
          .from('habits')
          .update({
            'title': t,
            'category_id': categoryId,
            'period': 'daily',
            'icon_key': iconKey,
            'color_key': colorKey,
            'start_date': _isoDate(startDate),
            'end_date': endDate == null ? null : _isoDate(endDate),
            'days_mask': daysMask,
            'is_active': isActive,
          })
          .eq('id', id)
          .eq('user_id', user.id);

      await refreshNow();
      return null;
    } on PostgrestException catch (e) {
      return '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.trim();
    } catch (e) {
      return e.toString();
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> deleteHabit(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    try {
      await supabase.from('habits').delete().eq('id', id).eq('user_id', user.id);
      await refreshNow();
      return null;
    } on PostgrestException catch (e) {
      return '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.trim();
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> toggleDoneForSelectedDate(String habitId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Kamu belum login.';

    final d = _dateOnly(selectedDate.value);
    final doneNow = isDoneForDate(habitId, d);

    try {
      await supabase.from('habit_logs').upsert(
        {
          'user_id': user.id,
          'habit_id': habitId,
          'log_date': _isoDate(d),
          'done': !doneNow,
        },
        onConflict: 'habit_id,log_date',
      );

      await refreshNow();
      return null;
    } on PostgrestException catch (e) {
      return '${e.code ?? ''} ${e.message} ${e.details ?? ''}'.trim();
    } catch (e) {
      return e.toString();
    }
  }
}
