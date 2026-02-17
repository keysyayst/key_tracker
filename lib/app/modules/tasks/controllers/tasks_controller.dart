import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum Weekday { mon, tue, wed, thu, fri }

extension WeekdayX on Weekday {
  String get labelId {
    switch (this) {
      case Weekday.mon:
        return 'Senin';
      case Weekday.tue:
        return 'Selasa';
      case Weekday.wed:
        return 'Rabu';
      case Weekday.thu:
        return 'Kamis';
      case Weekday.fri:
        return 'Jumat';
    }
  }
}

class ScheduleItem {
  final String id;
  final Weekday day;
  final TimeOfDay start;
  final TimeOfDay end;
  final String title;
  final String category;

  ScheduleItem({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    required this.title,
    required this.category,
  });

  ScheduleItem copyWith({
    Weekday? day,
    TimeOfDay? start,
    TimeOfDay? end,
    String? title,
    String? category,
  }) {
    return ScheduleItem(
      id: id,
      day: day ?? this.day,
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
      category: category ?? this.category,
    );
  }
}

class PlannedTask {
  final String id;
  final String scheduleId;
  final String title;
  final String note;
  final bool completed;

  PlannedTask({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.note,
    required this.completed,
  });

  PlannedTask copyWith({
    String? title,
    String? note,
    bool? completed,
  }) {
    return PlannedTask(
      id: id,
      scheduleId: scheduleId,
      title: title ?? this.title,
      note: note ?? this.note,
      completed: completed ?? this.completed,
    );
  }
}

class TasksController extends GetxController {
  final weekdays = const <Weekday>[
    Weekday.mon,
    Weekday.tue,
    Weekday.wed,
    Weekday.thu,
    Weekday.fri,
  ];

  final schedules = <ScheduleItem>[].obs;
  final tasks = <PlannedTask>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Dummy kecil biar langsung kebaca (boleh hapus kalau tidak perlu)
    final s1 = ScheduleItem(
      id: _id(),
      day: Weekday.mon,
      start: const TimeOfDay(hour: 8, minute: 0),
      end: const TimeOfDay(hour: 9, minute: 30),
      title: 'Belajar Flutter',
      category: 'Skill',
    );
    schedules.add(s1);
    tasks.add(
      PlannedTask(
        id: _id(),
        scheduleId: s1.id,
        title: 'Baca materi GetX',
        note: 'state, route, binding',
        completed: false,
      ),
    );
  }

  // ===== Query helper =====

  List<ScheduleItem> schedulesForDay(Weekday day) {
    final list = schedules.where((s) => s.day == day).toList();
    list.sort((a, b) => _toMinutes(a.start).compareTo(_toMinutes(b.start)));
    return list;
  }

  List<PlannedTask> tasksForSchedule(String scheduleId) {
    final list = tasks.where((t) => t.scheduleId == scheduleId).toList();
    // unfinished dulu
    list.sort((a, b) => (a.completed ? 1 : 0).compareTo(b.completed ? 1 : 0));
    return list;
  }

  // ===== CRUD Schedule =====

  void addSchedule(ScheduleItem item) {
    schedules.add(item);
  }

  void updateSchedule(ScheduleItem updated) {
    final i = schedules.indexWhere((s) => s.id == updated.id);
    if (i != -1) schedules[i] = updated;
    schedules.refresh();
  }

  void deleteSchedule(String id) {
    schedules.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.scheduleId == id);
    schedules.refresh();
    tasks.refresh();
  }

  // ===== CRUD Task =====

  void addTask(PlannedTask t) {
    tasks.add(t);
  }

  void updateTask(PlannedTask updated) {
    final i = tasks.indexWhere((t) => t.id == updated.id);
    if (i != -1) tasks[i] = updated;
    tasks.refresh();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    tasks.refresh();
  }

  void toggleTask(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    tasks[i] = tasks[i].copyWith(completed: !tasks[i].completed);
    tasks.refresh();
  }

  // ===== Helpers =====

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;
}
