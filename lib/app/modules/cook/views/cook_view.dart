import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_colors.dart';
import '../controllers/cook_controller.dart';

class CookView extends GetView<CookController> {
  const CookView({super.key});

  @override
  Widget build(BuildContext context) {
    // Jangan bikin instance berulang-ulang
    if (!Get.isRegistered<CookController>()) {
      Get.put(CookController());
    }

    return Scaffold(
      backgroundColor: AppColors.bgRose, // cute rose background [cite:40]
      appBar: AppBar(
        backgroundColor: AppColors.bgRose, // [cite:40]
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cook',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.pink500, // [cite:40]
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () {
          Get.bottomSheet(
            const _CookDishFormSheet(existing: null),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: const [
          SizedBox(height: 6),
          _CookHeader(),
          SizedBox(height: 12),
          Expanded(child: _CookBody()),
        ],
      ),
    );
  }
}

class _CookHeader extends GetView<CookController> {
  const _CookHeader();

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
        child: Obx(() {
          final m = controller.mode.value;

          String title;
          String subtitle;

          if (m == CookViewMode.today) {
            title = 'Hari ini';
            subtitle = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(controller.today);
          } else if (m == CookViewMode.upcoming3Days) {
            title = 'Akan datang';
            final start = controller.upcomingDates.first;
            final end = controller.upcomingDates.last;
            subtitle =
                '${DateFormat('d MMM', 'id_ID').format(start)} • ${DateFormat('d MMM yyyy', 'id_ID').format(end)}';
          } else {
            title = 'Tanggal dipilih';
            subtitle = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(controller.selectedDate.value);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ChipButton(
                      active: controller.isTodayMode,
                      text: 'Hari ini',
                      onTap: controller.setTodayMode,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChipButton(
                      active: controller.isUpcomingMode,
                      text: 'Akan datang',
                      onTap: controller.setUpcomingMode,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconChip(
                    icon: Icons.calendar_month_rounded,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.selectedDate.value,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink500),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) controller.pickCustomDate(picked);
                    },
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CookBody extends GetView<CookController> {
  const _CookBody();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.pink500));
      }

      if (controller.isEmptyForCurrentView) {
        return _EmptyCookState(
          onAdd: () {
            Get.bottomSheet(
              const _CookDishFormSheet(existing: null),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
        );
      }

      return controller.isUpcomingMode ? const _UpcomingList() : const _SingleDateList();
    });
  }
}

class _SingleDateList extends GetView<CookController> {
  const _SingleDateList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dishes = controller.dishesForSelectedDate;

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
        itemCount: dishes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _DishCard(dish: dishes[i]),
      );
    });
  }
}

class _UpcomingList extends GetView<CookController> {
  const _UpcomingList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final grouped = controller.upcomingGrouped;
      final dates = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
        itemCount: dates.length,
        itemBuilder: (_, idx) {
          final d = dates[idx];
          final list = grouped[d] ?? const <CookDish>[];

          return Padding(
            padding: EdgeInsets.only(bottom: idx == dates.length - 1 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(date: d),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: const Text(
                      'Belum ada rencana masak.',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final dish in list) ...[
                        _DishCard(dish: dish),
                        const SizedBox(height: 12),
                      ]
                    ],
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final DateTime date;
  const _SectionLabel({required this.date});

  @override
  Widget build(BuildContext context) {
    final text = DateFormat('EEEE, d MMM', 'id_ID').format(date);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: AppColors.pink500, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  final CookDish dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    final budgetText = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(dish.budget);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Get.bottomSheet(
            _CookDishFormSheet(existing: dish),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pink200.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.pink500),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(
                      dish.ingredients.trim().isEmpty ? 'Bahan: (belum diisi)' : 'Bahan: ${dish.ingredients}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textMuted, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.orange100),
                      ),
                      child: Text(budgetText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCookState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCookState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.soup_kitchen_rounded, size: 34, color: AppColors.pink500),
              const SizedBox(height: 10),
              const Text(
                'Belum ada rencana masak.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tambahkan masakan + bahan + budget dulu ya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah masakan', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CookDishFormSheet extends StatefulWidget {
  final CookDish? existing;
  const _CookDishFormSheet({required this.existing});

  @override
  State<_CookDishFormSheet> createState() => _CookDishFormSheetState();
}

class _CookDishFormSheetState extends State<_CookDishFormSheet> {
  late final CookController controller;

  late final TextEditingController nameC;
  late final TextEditingController ingC;
  late final TextEditingController budgetC;

  late DateTime formDate;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CookController>();

    nameC = TextEditingController(text: widget.existing?.name ?? '');
    ingC = TextEditingController(text: widget.existing?.ingredients ?? '');
    budgetC = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.budget.toInt().toString(),
    );

    formDate = widget.existing?.cookDate ?? controller.defaultFormDate;
  }

  @override
  void dispose() {
    nameC.dispose();
    ingC.dispose();
    budgetC.dispose();
    super.dispose();
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _labelForQuickDate(DateTime d) {
    if (_isSameDate(d, controller.today)) return 'Hari ini';
    return DateFormat('EEE d', 'id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    // Ini yang bikin sheet terlihat (white card), jadi tidak “kosong transparan”
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
              child: Column(
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
                          isEdit ? 'Edit masakan' : 'Tambah masakan',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark),
                        ),
                      ),
                      IconButton(onPressed: Get.back, icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // tanggal + pilih kalender
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('EEE, d MMM', 'id_ID').format(formDate),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
                          ),
                        ),
                        _IconChip(
                          icon: Icons.edit_calendar_rounded,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: formDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink500)),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => formDate = picked);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in <DateTime>[controller.today, ...controller.upcomingDates]) ...[
                          _MiniDateChip(
                            active: _isSameDate(formDate, d),
                            text: _labelForQuickDate(d),
                            onTap: () => setState(() => formDate = d),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  _NiceField(controller: nameC, label: 'Nama masakan', hint: 'Misal: Ayam kecap', maxLines: 1),
                  const SizedBox(height: 10),
                  _NiceField(controller: ingC, label: 'Bahan yang dibutuhkan', hint: 'Tulis per baris biar rapi', maxLines: 4),
                  const SizedBox(height: 10),
                  _NiceField(
                    controller: budgetC,
                    label: 'Budget (Rp)',
                    hint: 'Misal: 50000',
                    keyboardType: TextInputType.number,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 14),
                  Obx(() {
                    final busy = controller.isSubmitting.value;

                    return Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: busy ? null : Get.back,
                            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        if (isEdit) ...[
                          Expanded(
                            child: TextButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Hapus masakan?'),
                                          content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                          ],
                                        ),
                                      );
                                      if (ok != true) return;

                                      final err = await controller.deleteDish(widget.existing!.id);
                                      if (err == null) {
                                        Get.back(); // close sheet
                                        Get.snackbar('Dihapus', 'Masakan dihapus');
                                      } else {
                                        Get.snackbar('Error', err);
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              label: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();

                                    final budget = double.tryParse(budgetC.text.trim()) ?? 0;

                                    final err = isEdit
                                        ? await controller.updateDish(
                                            id: widget.existing!.id,
                                            cookDate: formDate,
                                            name: nameC.text,
                                            ingredients: ingC.text,
                                            budget: budget,
                                          )
                                        : await controller.addDish(
                                            cookDate: formDate,
                                            name: nameC.text,
                                            ingredients: ingC.text,
                                            budget: budget,
                                          );

                                    if (err == null) {
                                      Get.back(); // close sheet biar user nggak double submit
                                      Get.snackbar('Tersimpan', isEdit ? 'Perubahan disimpan' : 'Masakan ditambahkan');
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
                            child: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _NiceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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

class _ChipButton extends StatelessWidget {
  final bool active;
  final String text;
  final VoidCallback onTap;

  const _ChipButton({required this.active, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? AppColors.pink500 : AppColors.gray100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.pink500 : AppColors.gray200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: active ? Colors.white : AppColors.textDark),
          ),
        ),
      ),
    );
  }
}

class _MiniDateChip extends StatelessWidget {
  final bool active;
  final String text;
  final VoidCallback onTap;

  const _MiniDateChip({required this.active, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? AppColors.pink200.withOpacity(0.65) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.pink300 : AppColors.gray200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textDark),
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppColors.pink500),
        ),
      ),
    );
  }
}
