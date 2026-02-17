import 'package:flutter/material.dart';
import 'package:get/get.dart';

DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

String _dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}

String _id() => DateTime.now().microsecondsSinceEpoch.toString();

int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;

String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Jadwal = “judul jadwal” + jam + kategori + hari aktif.
/// Default yang kamu minta: Senin–Jumat.
class ScheduleTemplate {
  final String id;
  final String title; // judul jadwal
  final String category;
  final TimeOfDay start;
  final TimeOfDay end;

  /// 1..7 (Mon..Sun), contoh Mon-Fri = {1,2,3,4,5}
  final Set<int> activeWeekdays;

  ScheduleTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    required this.end,
    required this.activeWeekdays,
  });

  bool isActiveOn(DateTime date) => activeWeekdays.contains(date.weekday);
}

/// Task ditaruh di bawah 1 judul jadwal, tapi punya range (dibuat..deadline).
class TaskTemplate {
  final String id;
  final String scheduleId;

  final String title;
  final String note;

  /// Mulai muncul dari tanggal dibuat (hari ditambahkan).
  final DateTime activeFrom;

  /// Muncul sampai deadline (inclusive).
  final DateTime deadline;

  TaskTemplate({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.note,
    required this.activeFrom,
    required this.deadline,
  });
}

class TaskOccurrence {
  final DateTime date;

  final String taskId;
  final String taskTitle;
  final String taskNote;

  final String scheduleId;
  final String scheduleTitle;
  final String scheduleCategory;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;

  final DateTime activeFrom;
  final DateTime deadline;

  final bool completed;

  TaskOccurrence({
    required this.date,
    required this.taskId,
    required this.taskTitle,
    required this.taskNote,
    required this.scheduleId,
    required this.scheduleTitle,
    required this.scheduleCategory,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.activeFrom,
    required this.deadline,
    required this.completed,
  });

  String get scheduleTimeLabel => '${_fmtTime(scheduleStart)}–${_fmtTime(scheduleEnd)}';
}

class TaskPlannerService extends GetxService {
  final schedules = <ScheduleTemplate>[].obs;
  final tasks = <TaskTemplate>[].obs;

  /// checklist per tanggal: "taskId|yyyy-mm-dd"
  final completions = <String, bool>{}.obs;

  /// Dipakai untuk “memaksa” UI refresh ketika map/list berubah.
  final revision = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(schedules, (_) => revision.value++);
    ever(tasks, (_) => revision.value++);
    ever(completions, (_) => revision.value++);

    // Seed contoh biar tidak kosong (boleh hapus kalau kamu punya input jadwal sendiri)
    if (schedules.isEmpty) {
      final sch = ScheduleTemplate(
        id: _id(),
        title: 'Belajar',
        category: 'Skill',
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 9, minute: 0),
        activeWeekdays: {1, 2, 3, 4, 5}, // Mon-Fri
      );
      schedules.add(sch);

      addTask(
        scheduleId: sch.id,
        title: 'Baca materi',
        note: '',
        deadline: DateTime.now().add(const Duration(days: 7)),
      );
    }
  }

  ScheduleTemplate? scheduleById(String id) => schedules.firstWhereOrNull((s) => s.id == id);

  // ===== CRUD minimal (kalau kamu butuh dipanggil dari halaman input kamu) =====

  String addSchedule({
    required String title,
    required String category,
    required TimeOfDay start,
    required TimeOfDay end,
    Set<int>? activeWeekdays,
  }) {
    final id = _id();
    schedules.add(ScheduleTemplate(
      id: id,
      title: title,
      category: category,
      start: start,
      end: end,
      activeWeekdays: activeWeekdays ?? {1, 2, 3, 4, 5},
    ));
    schedules.refresh();
    return id;
  }

  String addTask({
    required String scheduleId,
    required String title,
    String note = '',
    DateTime? activeFrom,
    required DateTime deadline,
  }) {
    final start = normalizeDate(activeFrom ?? DateTime.now());
    final end = normalizeDate(deadline);
    final fixedEnd = end.isBefore(start) ? start : end;

    final id = _id();
    tasks.add(TaskTemplate(
      id: id,
      scheduleId: scheduleId,
      title: title,
      note: note,
      activeFrom: start,
      deadline: fixedEnd,
    ));
    tasks.refresh();
    return id;
  }

  // ===== Checklist =====

  void toggleCompletion(String taskId, DateTime date) {
    final d = normalizeDate(date);
    final k = _completionKey(taskId, d);
    final now = completions[k] ?? false;
    completions[k] = !now;
    completions.refresh();
  }

  bool isCompleted(String taskId, DateTime date) {
    final d = normalizeDate(date);
    return completions[_completionKey(taskId, d)] ?? false;
  }

  // ===== Inilah yang kamu minta: tampil dari dibuat..deadline =====
  List<TaskOccurrence> occurrencesForDate(DateTime date) {
    revision.value; // bikin getter ini reaktif untuk Obx()

    final d = normalizeDate(date);
    final out = <TaskOccurrence>[];

    for (final t in tasks) {
      // 1) Range tanggal (dibuat..deadline)
      if (d.isBefore(t.activeFrom) || d.isAfter(t.deadline)) continue;

      // 2) Harus sesuai jadwalnya (aktif di hari itu)
      final sch = scheduleById(t.scheduleId);
      if (sch == null) continue;
      if (!sch.isActiveOn(d)) continue;

      final done = isCompleted(t.id, d);

      out.add(TaskOccurrence(
        date: d,
        taskId: t.id,
        taskTitle: t.title,
        taskNote: t.note,
        scheduleId: sch.id,
        scheduleTitle: sch.title,
        scheduleCategory: sch.category,
        scheduleStart: sch.start,
        scheduleEnd: sch.end,
        activeFrom: t.activeFrom,
        deadline: t.deadline,
        completed: done,
      ));
    }

    // urut berdasarkan jam jadwal
    out.sort((a, b) {
      final c = _toMinutes(a.scheduleStart).compareTo(_toMinutes(b.scheduleStart));
      if (c != 0) return c;
      return a.taskTitle.compareTo(b.taskTitle);
    });

    return out;
  }

  String _completionKey(String taskId, DateTime d) => '$taskId|${_dateKey(d)}';
}
