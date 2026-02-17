import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/health_controller.dart';

class HealthView extends GetView<HealthController> {
  const HealthView({super.key});

  static const _pink = Color(0xFFFFC4D6);
  static const _lav = Color(0xFFE9E2FF);
  static const _mint = Color(0xFFCFF5E7);
  static const _ink = Color(0xFF2D2A32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFD),
      appBar: AppBar(
        title: const Text('Health'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WeightCard(
              onTapHistory: () => _openWeightHistory(context),
              onAdd: () => _openAddWeight(context),
            ),
            const SizedBox(height: 14),
            _WorkoutSection(
              onAddForDay: (day) => _openAddWorkout(context, day),
              onLongPressWorkout: (item) => _openWorkoutActions(context, item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddWeight(BuildContext context) async {
    final weightC = TextEditingController();
    final noteC = TextEditingController();
    DateTime picked = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Tambah BB',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CuteField(
                  controller: weightC,
                  label: 'Berat badan (kg)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                _CuteField(
                  controller: noteC,
                  label: 'Catatan (opsional)',
                ),
                const SizedBox(height: 10),
                _CuteDateRow(
                  initial: picked,
                  onPick: (d) => picked = d,
                ),
                const SizedBox(height: 12),
                _CutePrimaryButton(
                  text: 'Simpan',
                  onTap: () async {
                    final w = double.tryParse(weightC.text.trim());
                    if (w == null) return;
                    await controller.addWeight(
                      weightKg: w,
                      recordedAt: picked,
                      note: noteC.text.trim().isEmpty ? null : noteC.text.trim(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWeightHistory(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Riwayat BB',
          child: Obx(() {
            final items = controller.weights;
            if (controller.isLoadingWeights.value) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: Text('Belum ada data BB.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = items[i];
                final kg = it['weight_kg'].toString();
                final date = it['recorded_at'].toString();
                final note = (it['note'] ?? '').toString();

                return GestureDetector(
                  onLongPress: () => _openWeightActions(context, it),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lav.withOpacity(.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _pink.withOpacity(.7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.monitor_weight_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$kg kg • $date',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (note.isNotEmpty)
                                Text(
                                  note,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.more_horiz, color: Colors.black45),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  Future<void> _openWeightActions(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final id = item['id'] as String;
    final weightC = TextEditingController(text: item['weight_kg'].toString());
    final noteC = TextEditingController(text: (item['note'] ?? '').toString());
    DateTime picked =
        DateTime.tryParse(item['recorded_at'].toString()) ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'BB actions',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CuteMiniTile(
                icon: Icons.edit_outlined,
                text: 'Edit',
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) {
                      return _CuteSheet(
                        title: 'Edit BB',
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CuteField(
                                controller: weightC,
                                label: 'Berat badan (kg)',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _CuteField(
                                controller: noteC,
                                label: 'Catatan (opsional)',
                              ),
                              const SizedBox(height: 10),
                              _CuteDateRow(
                                initial: picked,
                                onPick: (d) => picked = d,
                              ),
                              const SizedBox(height: 12),
                              _CutePrimaryButton(
                                text: 'Simpan perubahan',
                                onTap: () async {
                                  final w =
                                      double.tryParse(weightC.text.trim());
                                  if (w == null) return;
                                  await controller.updateWeight(
                                    id: id,
                                    weightKg: w,
                                    recordedAt: picked,
                                    note: noteC.text.trim().isEmpty
                                        ? null
                                        : noteC.text.trim(),
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              _CuteMiniTile(
                icon: Icons.delete_outline,
                text: 'Hapus',
                onTap: () async {
                  Navigator.pop(context);
                  await controller.deleteWeight(id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddWorkout(BuildContext context, int day) async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    TimeOfDay? start;
    TimeOfDay? end;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Tambah workout',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CuteField(controller: titleC, label: 'Judul'),
                const SizedBox(height: 10),
                _CuteField(controller: descC, label: 'Deskripsi (opsional)'),
                const SizedBox(height: 10),
                _CuteTimeRow(
                  onPickStart: (t) => start = t,
                  onPickEnd: (t) => end = t,
                ),
                const SizedBox(height: 12),
                _CutePrimaryButton(
                  text: 'Simpan',
                  onTap: () async {
                    if (titleC.text.trim().isEmpty) return;

                    String? fmt(TimeOfDay? t) {
                      if (t == null) return null;
                      final hh = t.hour.toString().padLeft(2, '0');
                      final mm = t.minute.toString().padLeft(2, '0');
                      return '$hh:$mm:00';
                    }

                    await controller.addWorkout(
                      dayOfWeek: day,
                      title: titleC.text.trim(),
                      description:
                          descC.text.trim().isEmpty ? null : descC.text.trim(),
                      startTime: fmt(start),
                      endTime: fmt(end),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWorkoutActions(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final id = item['id'] as String;
    final titleC = TextEditingController(text: (item['title'] ?? '').toString());
    final descC =
        TextEditingController(text: (item['description'] ?? '').toString());

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Workout actions',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CuteMiniTile(
                icon: Icons.edit_outlined,
                text: 'Edit',
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) {
                      return _CuteSheet(
                        title: 'Edit workout',
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CuteField(controller: titleC, label: 'Judul'),
                              const SizedBox(height: 10),
                              _CuteField(
                                controller: descC,
                                label: 'Deskripsi (opsional)',
                              ),
                              const SizedBox(height: 12),
                              _CutePrimaryButton(
                                text: 'Simpan perubahan',
                                onTap: () async {
                                  if (titleC.text.trim().isEmpty) return;
                                  await controller.updateWorkout(
                                    id: id,
                                    title: titleC.text.trim(),
                                    description: descC.text.trim().isEmpty
                                        ? null
                                        : descC.text.trim(),
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              _CuteMiniTile(
                icon: Icons.delete_outline,
                text: 'Hapus',
                onTap: () async {
                  Navigator.pop(context);
                  await controller.deleteWorkout(id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeightCard extends GetView<HealthController> {
  const _WeightCard({required this.onTapHistory, required this.onAdd});

  final VoidCallback onTapHistory;
  final VoidCallback onAdd;

  static const _pink = Color(0xFFFFC4D6);
  static const _lav = Color(0xFFE9E2FF);
  static const _ink = Color(0xFF2D2A32);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapHistory,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_pink.withOpacity(.85), _lav.withOpacity(.75)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.65),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.favorite_border),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final latest = controller.latestWeight;
                final text = latest == null
                    ? 'Belum ada BB'
                    : '${latest['weight_kg']} kg';
                final date = latest == null
                    ? 'Tap untuk tambah/lihat riwayat'
                    : latest['recorded_at'].toString();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BB saat ini',
                      style: TextStyle(
                        color: _ink.withOpacity(.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.black54)),
                  ],
                );
              }),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              color: _ink,
              tooltip: 'Tambah BB',
            )
          ],
        ),
      ),
    );
  }
}

class _WorkoutSection extends GetView<HealthController> {
  const _WorkoutSection({
    required this.onAddForDay,
    required this.onLongPressWorkout,
  });

  final void Function(int day) onAddForDay;
  final void Function(Map<String, dynamic> item) onLongPressWorkout;

  static const _mint = Color(0xFFCFF5E7);
  static const _lav = Color(0xFFE9E2FF);
  static const _ink = Color(0xFF2D2A32);

  static const _days = <int, String>{
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Jadwal workout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            _CatLottieButton(
              assetPath: 'assets/lottie/cat_refresh.json',
              onTap: controller.fetchWorkouts,
              size: 62,
              scale: 1.35,
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, idx) {
            final day = idx + 1;
            final dayLabel = _days[day]!;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (day.isOdd ? _mint : _lav).withOpacity(.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      InkWell(
                        onTap: () => onAddForDay(day),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.add, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Obx(() {
                      final items = controller.workoutsForDay(day);
                      if (items.isEmpty) {
                        return Text(
                          'Belum ada.\nTap + untuk tambah.',
                          style: TextStyle(color: _ink.withOpacity(.55)),
                        );
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          final title = (it['title'] ?? '').toString();
                          final start = (it['start_time'] ?? '').toString();
                          final end = (it['end_time'] ?? '').toString();

                          String time = '';
                          if (start.isNotEmpty && start.length >= 5) {
                            time = start.substring(0, 5);
                          }
                          if (end.isNotEmpty && end.length >= 5) {
                            time = time.isEmpty
                                ? end.substring(0, 5)
                                : '$time-${end.substring(0, 5)}';
                          }

                          return GestureDetector(
                            onLongPress: () => onLongPressWorkout(it),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.fitness_center, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (time.isNotEmpty)
                                          Text(
                                            time,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.more_horiz,
                                    size: 18,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Tip: long-press item untuk edit/hapus (biar tombolnya tidak rame).',
          style: TextStyle(color: _ink.withOpacity(.55), fontSize: 12),
        ),
      ],
    );
  }
}

class _CatLottieButton extends StatefulWidget {
  const _CatLottieButton({
    required this.assetPath,
    required this.onTap,
    this.size = 62,
    this.scale = 1.35,
  });

  final String assetPath;
  final VoidCallback onTap;
  final double size;
  final double scale;

  @override
  State<_CatLottieButton> createState() => _CatLottieButtonState();
}

class _CatLottieButtonState extends State<_CatLottieButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFFC4D6);

    return Semantics(
      button: true,
      label: 'Refresh workout',
      child: InkResponse(
        onTap: () {
          widget.onTap();
          if (_c.duration != null) {
            _c
              ..stop()
              ..reset()
              ..forward();
          }
        },
        radius: widget.size * 0.75,
        splashColor: pink.withOpacity(0.16),
        highlightColor: pink.withOpacity(0.10),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Transform.scale(
              scale: widget.scale,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  pink,
                  BlendMode.modulate,
                ),
                child: Lottie.asset(
                  widget.assetPath,
                  controller: _c,
                  fit: BoxFit.contain,
                  onLoaded: (comp) {
                    _c.duration = comp.duration;
                    _c.repeat();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CuteSheet extends StatelessWidget {
  const _CuteSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(99),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CuteField extends StatelessWidget {
  const _CuteField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6F1FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}

class _CutePrimaryButton extends StatelessWidget {
  const _CutePrimaryButton({required this.text, required this.onTap});

  final String text;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async => onTap(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC4D6),
          foregroundColor: const Color(0xFF2D2A32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _CuteMiniTile extends StatelessWidget {
  const _CuteMiniTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F1FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CuteDateRow extends StatefulWidget {
  const _CuteDateRow({required this.initial, required this.onPick});

  final DateTime initial;
  final void Function(DateTime) onPick;

  @override
  State<_CuteDateRow> createState() => _CuteDateRowState();
}

class _CuteDateRowState extends State<_CuteDateRow> {
  late DateTime value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              '${value.toLocal()}'.substring(0, 10),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked == null) return;
            setState(() => value = picked);
            widget.onPick(picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}

class _CuteTimeRow extends StatefulWidget {
  const _CuteTimeRow({required this.onPickStart, required this.onPickEnd});

  final void Function(TimeOfDay) onPickStart;
  final void Function(TimeOfDay) onPickEnd;

  @override
  State<_CuteTimeRow> createState() => _CuteTimeRowState();
}

class _CuteTimeRowState extends State<_CuteTimeRow> {
  TimeOfDay? start;
  TimeOfDay? end;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TimeOfDay? v, VoidCallback onTap, Color bg) {
      final text = v == null
          ? label
          : '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Mulai', start, () async {
          final t = await showTimePicker(
            context: context,
            initialTime: start ?? TimeOfDay.now(),
          );
          if (t == null) return;
          setState(() => start = t);
          widget.onPickStart(t);
        }, const Color(0xFFEFF7FF)),
        const SizedBox(width: 10),
        chip('Selesai', end, () async {
          final t = await showTimePicker(
            context: context,
            initialTime: end ?? TimeOfDay.now(),
          );
          if (t == null) return;
          setState(() => end = t);
          widget.onPickEnd(t);
        }, const Color(0xFFFFF1F6)),
      ],
    );
  }
}
