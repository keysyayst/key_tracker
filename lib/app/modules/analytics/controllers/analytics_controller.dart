import 'package:get/get.dart';

import '../../../data/services/supabase_service.dart';
import '../../../utils/date_util.dart';

class DayStat {
  final String date; // yyyy-MM-dd
  final int done;
  final int total;

  DayStat({required this.date, required this.done, required this.total});

  double get ratio => total == 0 ? 0 : done / total;
}

class AnalyticsController extends GetxController {
  final loading = false.obs;
  final error = RxnString();

  final last7Days = <DayStat>[].obs;
  final focusMinutes7d = 0.obs;

  final income7d = 0.0.obs;
  final expense7d = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final uid = SupabaseService.uid;
    if (uid == null) {
      error.value = 'Kamu belum login.';
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final startStr = DateUtil.yMd(start);
      final endStr = DateUtil.yMd(DateTime(now.year, now.month, now.day));

      // Habit logs 7d
      final logs = await SupabaseService.client
          .from('habit_logs')
          .select('log_date, done')
          .eq('user_id', uid)
          .gte('log_date', startStr)
          .lte('log_date', endStr);

      final Map<String, int> doneByDay = {};
      final Map<String, int> totalByDay = {};
      for (final row in (logs as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final d = (m['log_date'] ?? '') as String;
        final done = (m['done'] ?? false) as bool;

        totalByDay[d] = (totalByDay[d] ?? 0) + 1;
        if (done) doneByDay[d] = (doneByDay[d] ?? 0) + 1;
      }

      final stats = <DayStat>[];
      for (int i = 0; i < 7; i++) {
        final day = DateTime(start.year, start.month, start.day).add(Duration(days: i));
        final key = DateUtil.yMd(day);
        stats.add(DayStat(
          date: key,
          done: doneByDay[key] ?? 0,
          total: totalByDay[key] ?? 0,
        ));
      }
      last7Days.assignAll(stats);

      // Focus sessions 7d
      final focus = await SupabaseService.client
          .from('focus_sessions')
          .select('actual_minutes, started_at')
          .eq('user_id', uid)
          .gte('started_at', '${startStr}T00:00:00')
          .lte('started_at', '${endStr}T23:59:59');

      int minutes = 0;
      for (final row in (focus as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        minutes += (m['actual_minutes'] ?? 0) as int;
      }
      focusMinutes7d.value = minutes;

      // Finance 7d (income/expense)
      final tx = await SupabaseService.client
          .from('finance_transactions')
          .select('txn_type, amount, txn_date')
          .eq('user_id', uid)
          .gte('txn_date', startStr)
          .lte('txn_date', endStr);

      double inc = 0;
      double exp = 0;
      for (final row in (tx as List)) {
        final m = Map<String, dynamic>.from(row as Map);
        final type = (m['txn_type'] ?? '') as String;
        final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
        if (type == 'income') inc += amount;
        if (type == 'expense') exp += amount;
      }
      income7d.value = inc;
      expense7d.value = exp;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
