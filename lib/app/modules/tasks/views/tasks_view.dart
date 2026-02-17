import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tasks_controller.dart';

class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Surface.bg,
      appBar: AppBar(
        backgroundColor: _Surface.header,
        elevation: 0,
        title: const Text(
          'Task Planner',
          style: TextStyle(fontWeight: FontWeight.w900, color: _Palette.textDark),
        ),
        iconTheme: const IconThemeData(color: _Palette.textDark),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HintCard(
              text:
                  'Alur simpel: Tambah jadwal (Senin–Jumat) → buka jadwalnya → tambah tugas di dalamnya.',
            ),
            const SizedBox(height: 14),
            ...controller.weekdays.map((day) => _DayCard(
                  day: day,
                  controller: controller,
                  onAddSchedule: () => _openScheduleSheet(context, initialDay: day),
                  onEditSchedule: (s) => _openScheduleSheet(context, initialDay: s.day, existing: s),
                  onDeleteSchedule: (id) => _confirmDeleteSchedule(context, id),
                  onAddTask: (scheduleId) => _openTaskSheet(context, scheduleId: scheduleId),
                  onEditTask: (t) => _openTaskSheet(context, scheduleId: t.scheduleId, existing: t),
                  onDeleteTask: (id) => _confirmDeleteTask(context, id),
                )),
          ],
        );
      }),
    );
  }

  // ================= Bottom sheets =================

  void _openScheduleSheet(
    BuildContext context, {
    required Weekday initialDay,
    ScheduleItem? existing,
  }) {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final categoryC = TextEditingController(text: existing?.category ?? '');
    var day = initialDay;
    var start = existing?.start ?? const TimeOfDay(hour: 8, minute: 0);
    var end = existing?.end ?? const TimeOfDay(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: StatefulBuilder(builder: (ctx, setState) {
            Future<void> pickStart() async {
              final picked = await showTimePicker(context: ctx, initialTime: start);
              if (picked != null) setState(() => start = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showTimePicker(context: ctx, initialTime: end);
              if (picked != null) setState(() => end = picked);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 44, height: 4, decoration: BoxDecoration(color: _Surface.border, borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _Palette.textDark),
                      ),
                    ),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 10),
                _Field(label: 'Judul', controller: titleC, hint: 'Contoh: Kuliah / Belajar / Gym'),
                const SizedBox(height: 10),
                _Field(label: 'Kategori', controller: categoryC, hint: 'Contoh: Skill / Health'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _DropdownDay(
                        value: day,
                        onChanged: (v) => setState(() => day = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _TimeChip(label: 'Mulai', time: start, onTap: pickStart)),
                    const SizedBox(width: 10),
                    Expanded(child: _TimeChip(label: 'Selesai', time: end, onTap: pickEnd)),
                  ],
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final title = titleC.text.trim();
                      final cat = categoryC.text.trim();
                      if (title.isEmpty || cat.isEmpty) {
                        Get.snackbar(
                          'Oops',
                          'Judul dan kategori wajib diisi',
                          backgroundColor: _Palette.pink,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }

                      if (existing == null) {
                        controller.addSchedule(ScheduleItem(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          day: day,
                          start: start,
                          end: end,
                          title: title,
                          category: cat,
                        ));
                      } else {
                        controller.updateSchedule(existing.copyWith(
                          day: day,
                          start: start,
                          end: end,
                          title: title,
                          category: cat,
                        ));
                      }

                      Get.back();
                    },
                    child: Text(existing == null ? 'Tambah' : 'Simpan'),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  void _openTaskSheet(
    BuildContext context, {
    required String scheduleId,
    PlannedTask? existing,
  }) {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final noteC = TextEditingController(text: existing?.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(color: _Surface.border, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      existing == null ? 'Tambah Tugas' : 'Edit Tugas',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _Palette.textDark),
                    ),
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              _Field(label: 'Judul tugas', controller: titleC, hint: 'Contoh: Kerjain latihan'),
              const SizedBox(height: 10),
              _Field(label: 'Catatan (opsional)', controller: noteC, hint: 'Boleh kosong…', maxLines: 3),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.pink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final title = titleC.text.trim();
                    if (title.isEmpty) {
                      Get.snackbar(
                        'Oops',
                        'Judul tugas wajib diisi',
                        backgroundColor: _Palette.pink,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                      return;
                    }

                    if (existing == null) {
                      controller.addTask(PlannedTask(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        scheduleId: scheduleId,
                        title: title,
                        note: noteC.text.trim(),
                        completed: false,
                      ));
                    } else {
                      controller.updateTask(existing.copyWith(
                        title: title,
                        note: noteC.text.trim(),
                      ));
                    }

                    Get.back();
                  },
                  child: Text(existing == null ? 'Tambah' : 'Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= Confirm dialogs =================

  void _confirmDeleteSchedule(BuildContext context, String scheduleId) {
    Get.defaultDialog(
      title: 'Hapus jadwal?',
      middleText: 'Tugas di dalam jadwal ini juga akan ikut terhapus.',
      textCancel: 'Batal',
      textConfirm: 'Hapus',
      confirmTextColor: Colors.white,
      buttonColor: _Palette.pink,
      onConfirm: () {
        controller.deleteSchedule(scheduleId);
        Get.back();
      },
    );
  }

  void _confirmDeleteTask(BuildContext context, String id) {
    Get.defaultDialog(
      title: 'Hapus tugas?',
      middleText: 'Tugas ini akan dihapus dari daftar.',
      textCancel: 'Batal',
      textConfirm: 'Hapus',
      confirmTextColor: Colors.white,
      buttonColor: _Palette.pink,
      onConfirm: () {
        controller.deleteTask(id);
        Get.back();
      },
    );
  }
}

// ================= Widgets =================

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.controller,
    required this.onAddSchedule,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final Weekday day;
  final TasksController controller;
  final VoidCallback onAddSchedule;
  final ValueChanged<ScheduleItem> onEditSchedule;
  final ValueChanged<String> onDeleteSchedule;

  final ValueChanged<String> onAddTask;
  final ValueChanged<PlannedTask> onEditTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final items = controller.schedulesForDay(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Surface.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(day.labelId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _Palette.textDark)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddSchedule,
                icon: const Icon(Icons.add_rounded, size: 18, color: _Palette.pink),
                label: const Text('Jadwal', style: TextStyle(color: _Palette.pink, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (items.isEmpty)
            const Text('Belum ada jadwal.', style: TextStyle(color: _Palette.muted, fontWeight: FontWeight.w700))
          else
            ...items.map((s) => _ScheduleTile(
                  schedule: s,
                  tasks: controller.tasksForSchedule(s.id),
                  onToggle: controller.toggleTask,
                  onAddTask: () => onAddTask(s.id),
                  onEditSchedule: () => onEditSchedule(s),
                  onDeleteSchedule: () => onDeleteSchedule(s.id),
                  onEditTask: onEditTask,
                  onDeleteTask: onDeleteTask,
                )),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.tasks,
    required this.onToggle,
    required this.onAddTask,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final ScheduleItem schedule;
  final List<PlannedTask> tasks;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddTask;
  final VoidCallback onEditSchedule;
  final VoidCallback onDeleteSchedule;
  final ValueChanged<PlannedTask> onEditTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    String t(TimeOfDay x) => '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _Surface.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Surface.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.w900, color: _Palette.textDark)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t(schedule.start)}–${t(schedule.end)} • ${schedule.category}',
              style: const TextStyle(color: _Palette.muted, fontWeight: FontWeight.w700),
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: _Palette.muted),
            onSelected: (v) {
              if (v == 'edit') onEditSchedule();
              if (v == 'delete') onDeleteSchedule();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
          children: [
            Row(
              children: [
                const Text('Tugas', style: TextStyle(fontWeight: FontWeight.w900, color: _Palette.textDark)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add_rounded, size: 18, color: _Palette.pink),
                  label: const Text('Tambah', style: TextStyle(color: _Palette.pink, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (tasks.isEmpty)
              const Text('Belum ada tugas.', style: TextStyle(color: _Palette.muted, fontWeight: FontWeight.w700))
            else
              ...tasks.map((x) => _TaskRow(
                    task: x,
                    onToggle: () => onToggle(x.id),
                    onEdit: () => onEditTask(x),
                    onDelete: () => onDeleteTask(x.id),
                  )),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannedTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: task.completed ? _Palette.muted : _Palette.textDark,
      decoration: task.completed ? TextDecoration.lineThrough : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Surface.border),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: task.completed ? _Palette.pink : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.completed ? _Palette.pink : _Palette.muted.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: task.completed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: titleStyle),
              if (task.note.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(task.note, style: const TextStyle(color: _Palette.muted, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _Palette.muted),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Surface.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _Surface.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Surface.border),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: _Palette.pink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: _Palette.muted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _Palette.textDark)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: _Surface.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _Surface.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _Surface.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _Palette.pink.withValues(alpha: 0.55), width: 1.5)),
        ),
      ),
    ]);
  }
}

class _DropdownDay extends StatelessWidget {
  const _DropdownDay({required this.value, required this.onChanged});
  final Weekday value;
  final ValueChanged<Weekday> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _Surface.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _Surface.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Weekday>(
          value: value,
          isExpanded: true,
          items: const [Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri]
              .map((d) => DropdownMenuItem(value: d, child: Text(d.labelId, style: const TextStyle(fontWeight: FontWeight.w800))))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: _Surface.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _Surface.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _Palette.muted)),
            const SizedBox(height: 4),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w900, color: _Palette.textDark)),
          ],
        ),
      ),
    );
  }
}

class _Palette {
  static const pink = Color(0xFFFB7185);
  static const muted = Color(0xFF94A3B8);
  static const textDark = Color(0xFF0F172A);
}

class _Surface {
  static const bg = Color(0xFFFFF5F6);
  static const header = Color(0xFFFFE7EA);
  static const border = Color(0xFFF1F5F9);
}
