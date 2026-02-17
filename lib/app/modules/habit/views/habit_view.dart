import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

import '../../../themes/app_colors.dart';
import '../controllers/habit_controller.dart';

class HabitView extends GetView<HabitController> {
  const HabitView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HabitController>()) {
      Get.put(HabitController(), permanent: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Habit',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        leading: IconButton(
          onPressed: Get.back,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textDark),
          ),
        ),
        actions: [
          Obx(() {
            return IconButton(
              tooltip: controller.showAllHabits.value ? 'Filter tanggal: OFF' : 'Filter tanggal: ON',
              onPressed: () => controller.showAllHabits.value = !controller.showAllHabits.value,
              icon: Icon(
                controller.showAllHabits.value ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
                color: AppColors.textDark,
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.pink500,
        foregroundColor: Colors.white,
        onPressed: () {
          Get.bottomSheet(
            HabitFormSheet(existing: null),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          const _HabitHeader(),
          const SizedBox(height: 12),
          const Expanded(child: _HabitBody()),
        ],
      ),
    );
  }
}

class _HabitHeader extends GetView<HabitController> {
  const _HabitHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gray100),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final d = controller.selectedDate.value;
              final subtitle = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(d);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masih konsisten hari ini?',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            const _CalendarDense(),
          ],
        ),
      ),
    );
  }
}

class _CalendarDense extends GetView<HabitController> {
  const _CalendarDense();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final focused = controller.selectedDate.value;
      final current = DateTime.now();
      final start = DateTime(current.year, current.month, current.day).subtract(const Duration(days: 30));
      final end = DateTime(current.year, current.month, current.day).add(const Duration(days: 365));

      return EasyDateTimeLinePicker.itemBuilder(
        firstDate: start,
        lastDate: end,
        focusedDate: focused,
        currentDate: DateTime(current.year, current.month, current.day),
        itemExtent: 42,
        daySeparatorPadding: 0,
        timelineOptions: const TimelineOptions(height: 52),
        headerOptions: const HeaderOptions(headerType: HeaderType.none),
        onDateChange: controller.pickDate,
        itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
          final bg = isSelected ? AppColors.pink500 : Colors.white;
          final fg = isSelected ? Colors.white : AppColors.textDark;
          final borderColor = isSelected ? Colors.transparent : (isToday ? AppColors.pink500 : AppColors.gray200);

          return InkResponse(
            onTap: onTap,
            radius: 28,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: isToday && !isSelected ? 2 : 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: fg),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _HabitBody extends GetView<HabitController> {
  const _HabitBody();

  IconData _iconForKey(String key) {
    switch (key) {
      case 'pray':
        return Icons.mosque_rounded;
      case 'meditate':
        return Icons.self_improvement_rounded;
      case 'journal':
        return Icons.menu_book_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'skincare':
        return Icons.spa_rounded;
      case 'hair':
        return Icons.content_cut_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.pink500));
      }

      final list = controller.showAllHabits.value
          ? (controller.habits.toList()..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())))
          : controller.habitsForSelectedDate;

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.gray100),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 34, color: AppColors.pink500),
                  SizedBox(height: 10),
                  Text('Belum ada habit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  SizedBox(height: 6),
                  Text('Tekan Tambah untuk mulai konsisten ya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final h = list[i];
          final done = controller.isDoneForDate(h.id, controller.selectedDate.value);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () async {
                final err = await controller.toggleDoneForSelectedDate(h.id);
                if (err != null) Get.snackbar('Error', err);
              },
              onLongPress: () {
                Get.bottomSheet(
                  HabitFormSheet(existing: h),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.pink200.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_iconForKey(h.iconKey), color: AppColors.pink500),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        h.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: done ? AppColors.pink500 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: done ? AppColors.pink500 : AppColors.gray200, width: 2),
                      ),
                      child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// ===================== FORM SHEET =====================

class HabitFormSheet extends StatefulWidget {
  final Habit? existing;
  const HabitFormSheet({super.key, required this.existing});

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  late final HabitController controller;
  late final TextEditingController titleC;

  String? categoryId;
  String iconKey = 'sparkle';
  String colorKey = 'pink';

  DateTime startDate = DateTime.now();
  DateTime? endDate;

  bool everyday = true;
  final Set<int> weekdays = <int>{1, 2, 3, 4, 5, 6, 7}; // Mon..Sun

  bool get isEdit => widget.existing != null;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    controller = Get.find<HabitController>();

    titleC = TextEditingController(text: widget.existing?.title ?? '');

    final ex = widget.existing;
    startDate = ex?.startDate ?? controller.selectedDate.value;
    endDate = ex?.endDate;

    categoryId = ex?.categoryId;
    iconKey = ex?.iconKey ?? 'sparkle';
    colorKey = ex?.colorKey ?? 'pink';

    if (categoryId == null && controller.categories.isNotEmpty) {
      categoryId = controller.categories.first.id;
      final cat = controller.categoryById(categoryId!);
      if (cat != null) {
        iconKey = cat.iconKey;
        colorKey = cat.colorKey;
      }
    }

    if (ex != null) {
      final mask = ex.daysMask;
      everyday = mask == HabitController.maskEveryday();
      weekdays.clear();
      for (int wd = 1; wd <= 7; wd++) {
        final idx = (wd - 1) % 7;
        if ((mask & (1 << idx)) != 0) weekdays.add(wd);
      }
      if (weekdays.isEmpty) {
        everyday = true;
        weekdays.addAll({1, 2, 3, 4, 5, 6, 7});
      }
    }
  }

  @override
  void dispose() {
    titleC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxEnd = DateTime(2027, 12, 31);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SingleChildScrollView(
              child: Obx(() {
                final busy = controller.isSubmitting.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(999)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit habit' : 'Tambah habit',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark),
                          ),
                        ),
                        IconButton(onPressed: Get.back, icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _NiceField(controller: titleC, label: 'Nama habit', hint: 'Misal: Journaling 5 menit', maxLines: 1),
                    const SizedBox(height: 10),

                    _CategoryPickerDb(
                      value: categoryId,
                      onChanged: (id) {
                        setState(() {
                          categoryId = id;
                          final cat = controller.categoryById(id);
                          if (cat != null) {
                            iconKey = cat.iconKey;
                            colorKey = cat.colorKey;
                          }
                        });
                      },
                      onAdd: () async {
                        final err = await Get.bottomSheet<String?>(
                          _AddCategorySheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                        if (err != null) Get.snackbar('Error', err);
                        if (controller.categories.isNotEmpty && categoryId == null) {
                          setState(() => categoryId = controller.categories.first.id);
                        }
                      },
                    ),

                    const SizedBox(height: 10),
                    _SchedulePicker(
                      everyday: everyday,
                      weekdays: weekdays,
                      onEverydayChanged: (v) {
                        setState(() {
                          everyday = v;
                          if (everyday) {
                            weekdays
                              ..clear()
                              ..addAll({1, 2, 3, 4, 5, 6, 7});
                          }
                        });
                      },
                      onToggleWeekday: (wd) {
                        setState(() {
                          everyday = false;
                          if (weekdays.contains(wd)) {
                            weekdays.remove(wd);
                          } else {
                            weekdays.add(wd);
                          }
                          if (weekdays.isEmpty) {
                            weekdays.addAll({1, 2, 3, 4, 5, 6, 7});
                            everyday = true;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    _DateRow(
                      label: 'Mulai',
                      value: _dateOnly(startDate),
                      onTap: busy
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dateOnly(startDate),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: maxEnd,
                              );
                              if (picked != null) setState(() => startDate = picked);
                            },
                    ),
                    const SizedBox(height: 10),
                    _DateRow(
                      label: 'Sampai',
                      value: endDate == null ? null : _dateOnly(endDate!),
                      trailingText: endDate == null ? 'Tidak dibatasi' : null,
                      onTap: busy
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? _dateOnly(startDate),
                                firstDate: _dateOnly(startDate),
                                lastDate: maxEnd,
                              );
                              if (picked != null) setState(() => endDate = picked);
                            },
                      onClear: busy ? null : () => setState(() => endDate = null),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (isEdit)
                          Expanded(
                            child: TextButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Hapus habit?'),
                                          content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                          ],
                                        ),
                                      );
                                      if (ok != true) return;
                                      final err = await controller.deleteHabit(widget.existing!.id);
                                      if (err == null) {
                                        Get.back();
                                        Get.snackbar('Dihapus', 'Habit dihapus');
                                      } else {
                                        Get.snackbar('Error', err);
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              label: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        if (isEdit) const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();

                                    final mask = everyday
                                        ? HabitController.maskEveryday()
                                        : HabitController.maskFromWeekdays(weekdays);

                                    if (categoryId == null || categoryId!.isEmpty) {
                                      Get.snackbar('Error', 'Pilih kategori dulu.');
                                      return;
                                    }

                                    final err = isEdit
                                        ? await controller.updateHabit(
                                            id: widget.existing!.id,
                                            title: titleC.text,
                                            categoryId: categoryId!,
                                            iconKey: iconKey,
                                            colorKey: colorKey,
                                            startDate: startDate,
                                            endDate: endDate,
                                            daysMask: mask,
                                            isActive: true,
                                          )
                                        : await controller.createHabit(
                                            title: titleC.text,
                                            categoryId: categoryId!,
                                            iconKey: iconKey,
                                            colorKey: colorKey,
                                            startDate: startDate,
                                            endDate: endDate,
                                            daysMask: mask,
                                          );

                                    if (err == null) {
                                      Get.back();
                                      Get.snackbar('Tersimpan', isEdit ? 'Habit diperbarui' : 'Habit ditambahkan');
                                    } else {
                                      Get.snackbar('Error', err);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pink500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(isEdit ? 'Simpan' : 'Tambah', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== UI Helpers =====

class _NiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _NiceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.gray100,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

class _CategoryPickerDb extends StatelessWidget {
  final String? value; // categoryId
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  const _CategoryPickerDb({
    required this.value,
    required this.onChanged,
    required this.onAdd,
  });

  IconData _iconForKey(String key) {
    switch (key) {
      case 'pray':
        return Icons.mosque_rounded;
      case 'meditate':
        return Icons.self_improvement_rounded;
      case 'journal':
        return Icons.menu_book_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'skincare':
        return Icons.spa_rounded;
      case 'hair':
        return Icons.content_cut_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HabitController>();

    Widget chip({
      required bool active,
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.pink200.withOpacity(0.6) : AppColors.gray100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? AppColors.pink300 : AppColors.gray200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textDark),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textDark)),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.isCatLoading.value) {
        return const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: CircularProgressIndicator(color: AppColors.pink500),
          ),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in controller.categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip(
                  active: value == item.id,
                  label: item.name,
                  icon: _iconForKey(item.iconKey),
                  onTap: () => onChanged(item.id),
                ),
              ),
            chip(
              active: false,
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: onAdd,
            ),
          ],
        ),
      );
    });
  }
}

class _AddCategorySheet extends StatefulWidget {
  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final nameC = TextEditingController();
  String iconKey = 'sparkle';
  String colorKey = 'pink';

  @override
  void dispose() {
    nameC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HabitController>();

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Obx(() {
              final busy = c.isSubmitting.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(999)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Tambah kategori', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                      IconButton(onPressed: Get.back, icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _NiceField(controller: nameC, label: 'Nama kategori', hint: 'Misal: Belajar', maxLines: 1),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: iconKey,
                    items: const [
                      DropdownMenuItem(value: 'sparkle', child: Text('Sparkle')),
                      DropdownMenuItem(value: 'pray', child: Text('Pray')),
                      DropdownMenuItem(value: 'meditate', child: Text('Meditate')),
                      DropdownMenuItem(value: 'journal', child: Text('Journal')),
                      DropdownMenuItem(value: 'workout', child: Text('Workout')),
                      DropdownMenuItem(value: 'skincare', child: Text('Skincare')),
                      DropdownMenuItem(value: 'hair', child: Text('Hair')),
                    ],
                    onChanged: busy ? null : (v) => setState(() => iconKey = v ?? 'sparkle'),
                    decoration: InputDecoration(
                      labelText: 'Icon',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final err = await c.createCategory(
                                name: nameC.text,
                                iconKey: iconKey,
                                colorKey: colorKey,
                              );
                              if (err == null) {
                                Get.back(result: null);
                              } else {
                                Get.back(result: err);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pink500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  final bool everyday;
  final Set<int> weekdays; // Mon..Sun => 1..7
  final ValueChanged<bool> onEverydayChanged;
  final void Function(int weekday) onToggleWeekday;

  const _SchedulePicker({
    required this.everyday,
    required this.weekdays,
    required this.onEverydayChanged,
    required this.onToggleWeekday,
  });

  @override
  Widget build(BuildContext context) {
    Widget dayChip(int wd, String label) {
      final active = weekdays.contains(wd);
      return InkWell(
        onTap: () => onToggleWeekday(wd),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.pink200.withOpacity(0.65) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? AppColors.pink300 : AppColors.gray200),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textDark)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Jadwal', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
              ),
              Switch(
                value: everyday,
                onChanged: onEverydayChanged,
                activeColor: AppColors.pink500,
              ),
              Text(
                everyday ? 'Setiap hari' : 'Hari tertentu',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              dayChip(1, 'Sen'),
              dayChip(2, 'Sel'),
              dayChip(3, 'Rab'),
              dayChip(4, 'Kam'),
              dayChip(5, 'Jum'),
              dayChip(6, 'Sab'),
              dayChip(7, 'Min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String? trailingText;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.value,
    this.trailingText,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null ? (trailingText ?? '-') : DateFormat('EEE, d MMM yyyy', 'id_ID').format(value!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: $text',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
            ),
            if (value != null && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
