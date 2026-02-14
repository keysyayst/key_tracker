import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/cute_cat_mascot.dart';
import '../../../widgets/pastel_card.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: CuteSurface.bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _triSectionFloating(),
                    const SizedBox(height: 18),
                    _skillQuickCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: CuteSurface.header,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Ubah ke Center biar sejajar
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TANGGAL
                    Obx(() {
                      final d = controller.today.value;
                      final s = DateFormat('EEEE, d MMM', 'id_ID').format(d);
                      return Text(
                        s,
                        style: TextStyle(
                          color: CutePalette.pink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      );
                    }),
                    const SizedBox(height: 3),
                    
                    // NAMA USER
                    Obx(() {
                      String name = controller.profileC.savedDisplayName.value;
                      if (name.isEmpty) {
                        name = controller.profileC.email?.split('@')[0] ?? 'Teman';
                      }
                      return Text(
                        'Hai, $name!', 
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    
                    const SizedBox(height: 6),

                    // PESAN SEMANGAT
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.moodMessage.value,
                        style: TextStyle(
                          color: CutePalette.pink.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // MASCOT BESAR
              GestureDetector(
                onTap: () => _showMoodCheckDialog(Get.context!),
                child: Obx(() => Hero( // Tambah Hero kalau mau efek transisi antar halaman (opsional)
                  tag: 'mascot',
                  child: CuteCatMascot(
                    mood: controller.currentMood.value,
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CuteSurface.border),
            ),
            child: _calendarPickerDense(),
          ),
        ],
      ),
    );
  }

  // === POPUP MOOD CHECKER ===
  void _showMoodCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Good Morning! ☀️',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gimana perasaanmu hari ini?',
                  style: TextStyle(fontSize: 14, color: CutePalette.muted),
                ),
                const SizedBox(height: 24),
                
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _moodOption(CatMood.happy, 'Happy', '😊'),
                    _moodOption(CatMood.excited, 'Excited', '🤩'),
                    _moodOption(CatMood.neutral, 'B aja', '😐'),
                    _moodOption(CatMood.tired, 'Capek', '😴'),
                    _moodOption(CatMood.sad, 'Sad', '😢'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moodOption(CatMood mood, String label, String emoji) {
    return GestureDetector(
      onTap: () {
        controller.setMood(mood);
        Get.back();
        Get.snackbar(
          'Mood Disimpan', 
          'Dashboard kamu menyesuaikan! 🐱',
          backgroundColor: CutePalette.pink,
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          borderRadius: 16,
          duration: const Duration(seconds: 1),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CuteSurface.bg,
              shape: BoxShape.circle,
              border: Border.all(color: CuteSurface.border),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CutePalette.muted)
          ),
        ],
      ),
    );
  }

  Widget _calendarPickerDense() {
    return Obx(() {
      final focused = controller.selectedDate.value;
      final current = controller.today.value;

      final start = DateTime(current.year, current.month, current.day).subtract(const Duration(days: 30));
      final end = DateTime(current.year, current.month, current.day).add(const Duration(days: 90));

      return EasyDateTimeLinePicker.itemBuilder(
        firstDate: start,
        lastDate: end,
        focusedDate: focused,
        currentDate: current,
        itemExtent: 42,
        daySeparatorPadding: 0,
        timelineOptions: const TimelineOptions(height: 52),
        headerOptions: HeaderOptions(
          headerType: HeaderType.picker,
          headerBuilder: (context, date, onTap) {
            final monthYear = DateFormat('MMMM yyyy', 'id_ID').format(date);
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthYear,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more_rounded, size: 18, color: CutePalette.muted),
                  ],
                ),
              ),
            );
          },
        ),
        onDateChange: controller.pickDate,
        itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
          final bg = isSelected ? CutePalette.pink : Colors.white;
          final fg = isSelected ? Colors.white : AppColors.textDark;
          final borderColor = isSelected
              ? Colors.transparent
              : (isToday ? CutePalette.pink.withValues(alpha: 0.75) : CuteSurface.border);

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
                child: Text('${date.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: fg)),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _triSectionFloating() {
    return Obx(() {
      final idx = controller.sectionIndex.value;
      const tabsH = 68.0;
      const cardH = 420.0;
      const overlap = 24.0;
      const gapBelowTabs = 16.0;
      final cardTop = tabsH - overlap;
      final contentTopPad = overlap + gapBelowTabs;

      return SizedBox(
        height: cardTop + cardH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, right: 0, top: cardTop, height: cardH,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, contentTopPad, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: CuteSurface.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: PageView(
                  controller: controller.sectionPageController,
                  onPageChanged: controller.onSectionPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _TasksPanel(controller: controller),
                    _WalletPanel(controller: controller),
                    _JournalPanel(controller: controller),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12, right: 12, top: 0,
              child: CuteTriTabsIconOnly(
                index: idx,
                onTap: controller.setSection,
                items: const [
                  CuteTriTabItem(icon: Icons.checklist_rounded, label: 'Tasks'),
                  CuteTriTabItem(icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
                  CuteTriTabItem(icon: Icons.book_rounded, label: 'Journal'),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _skillQuickCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            'Level Up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
        ),
        PastelCard(
          background: Colors.white,
          borderColor: CuteSurface.border,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CuteSurface.bg, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.psychology_alt_rounded, color: CutePalette.lavender, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Flutter Master', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('Sedang belajar Navigasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CutePalette.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== STYLE & WIDGETS PENDUKUNG =====================

class CutePalette {
  static const pink = Color(0xFFFB7185);
  static const sky = Color(0xFF60A5FA);
  static const lavender = Color(0xFFA78BFA);
  static const muted = Color(0xFF94A3B8);
}

class CuteSurface {
  static const bg = Color(0xFFFFF5F6);
  static const header = Color(0xFFFFE7EA);
  static const card = Colors.white;
  static const border = Color(0xFFF1F5F9);
}

class CuteTriTabItem {
  const CuteTriTabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class CuteTriTabsIconOnly extends StatelessWidget {
  const CuteTriTabsIconOnly({super.key, required this.index, required this.onTap, required this.items});
  final int index;
  final ValueChanged<int> onTap;
  final List<CuteTriTabItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const gap = 10.0;
      const pad = 6.0;
      final innerW = w - (pad * 2);
      const minInactive = 60.0;
      var activeW = (innerW * 0.52);
      final maxActive = innerW - (2 * (minInactive + gap));
      activeW = activeW.clamp(120.0, maxActive);
      final inactiveW = (innerW - activeW - 2 * gap) / 2;
      final widths = List<double>.generate(3, (i) => i == index ? activeW : inactiveW);
      final lefts = <double>[0, widths[0] + gap, widths[0] + gap + widths[1] + gap];

      return Container(
        height: 64,
        padding: const EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CuteSurface.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: List.generate(3, (i) {
            final active = i == index;
            return AnimatedPositioned(
              key: ValueKey('tab-pos-$i'),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: lefts[i], top: 0, bottom: 0, width: widths[i],
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: active ? [BoxShadow(color: CutePalette.pink.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: active
                          ? Text(items[i].label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: CutePalette.pink))
                          : Icon(items[i].icon, size: 24, color: CutePalette.muted),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

class CategoryStyle {
  const CategoryStyle({required this.accent, required this.bg});
  final Color accent;
  final Color bg;
  factory CategoryStyle.of(String category) {
    final key = category.trim().toLowerCase();
    if (key == 'health') return CategoryStyle(accent: CutePalette.sky, bg: Color(0xFFEFF6FF));
    if (key == 'skill') return CategoryStyle(accent: CutePalette.lavender, bg: Color(0xFFF5F3FF));
    if (key == 'home') return CategoryStyle(accent: CutePalette.pink, bg: Color(0xFFFFF1F2));
    return CategoryStyle(accent: CutePalette.pink, bg: Color(0xFFFFF1F2));
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});
  final String category;
  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: s.accent.withValues(alpha: 0.2))),
      child: Text(category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.accent)),
    );
  }
}

class _TasksPanel extends StatelessWidget {
  const _TasksPanel({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = controller.tasksForSelectedDate;
      final p = controller.progressPercentage;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(height: 6, color: CuteSurface.bg, child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (p.clamp(0, 100)) / 100.0, child: Container(color: CutePalette.pink))),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text('No tasks yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CutePalette.muted)))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      final cs = CategoryStyle.of(t.category);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => controller.toggleTask(t.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.completed ? Color(0xFFF8FAFC) : cs.bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: t.completed ? Colors.transparent : cs.accent.withValues(alpha: 0.1), width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.accent.withValues(alpha: 0.1))), child: Icon(t.icon, size: 20, color: cs.accent)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.completed ? CutePalette.muted : AppColors.textDark, decoration: t.completed ? TextDecoration.lineThrough : null)), const SizedBox(height: 6), CategoryChip(category: t.category)])),
                                AnimatedContainer(duration: const Duration(milliseconds: 200), width: 24, height: 24, decoration: BoxDecoration(color: t.completed ? CutePalette.pink : Colors.white, shape: BoxShape.circle, border: Border.all(color: t.completed ? CutePalette.pink : CutePalette.muted.withValues(alpha: 0.3), width: 2)), child: t.completed ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String rupiah(int v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);
      Widget tile({required Color accent, required String label, required String value, required IconData icon}) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: 0.15))),
          child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 22)), const SizedBox(width: 14), Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark))]),
        );
      }
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          tile(accent: CutePalette.sky, label: 'Sisa Mingguan', value: rupiah(controller.weeklyBudgetRemaining.value), icon: Icons.calendar_view_week_rounded),
          tile(accent: CutePalette.lavender, label: 'Sisa Bulanan', value: rupiah(controller.monthlyBudgetRemaining.value), icon: Icons.calendar_month_rounded),
          tile(accent: CutePalette.pink, label: 'Total Saldo', value: rupiah(controller.totalSaldo.value), icon: Icons.account_balance_rounded),
          tile(accent: CutePalette.pink, label: 'Tabungan', value: rupiah(controller.tabungan.value), icon: Icons.savings_rounded),
        ],
      );
    });
  }
}

class _JournalPanel extends StatelessWidget {
  const _JournalPanel({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final content = controller.currentJournalContent;
      final isEmpty = content.isEmpty;
      final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(controller.selectedDate.value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEmpty ? 'Belum ada cerita' : 'Dear Diary,', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CutePalette.muted)),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showJournalEditor(context, content, dateStr),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: CutePalette.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: CutePalette.pink.withValues(alpha: 0.2))),
                    child: Row(children: [Icon(isEmpty ? Icons.add_rounded : Icons.edit_rounded, size: 14, color: CutePalette.pink), const SizedBox(width: 4), Text(isEmpty ? 'Tulis' : 'Edit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CutePalette.pink))]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFFFF9FA), borderRadius: BorderRadius.circular(24), border: Border.all(color: CutePalette.pink.withValues(alpha: 0.2), width: 1.5)),
              child: isEmpty
                  ? _buildEmptyState(context, content, dateStr)
                  : SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textDark))),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, String content, String dateStr) {
    return GestureDetector(
      onTap: () => _showJournalEditor(context, content, dateStr),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: CutePalette.pink.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]), child: const Icon(Icons.edit_note_rounded, color: CutePalette.pink, size: 32)),
          const SizedBox(height: 16),
          const Text('Apa cerita harimu?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Ketuk tombol edit di atas untuk mulai...', style: TextStyle(fontSize: 12, color: CutePalette.muted)),
        ],
      ),
    );
  }

  void _showJournalEditor(BuildContext context, String initialContent, String dateLabel) {
    final textController = TextEditingController(text: initialContent);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: CuteSurface.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Jurnal Harian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)), Text(dateLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CutePalette.pink))]),
                  ElevatedButton(
                    onPressed: () {
                      controller.saveJournal(textController.text);
                      Get.back();
                      Get.snackbar('Disimpan!', 'Ceritamu aman ✨', backgroundColor: CutePalette.pink, colorText: Colors.white, margin: const EdgeInsets.all(20), borderRadius: 16, duration: const Duration(seconds: 1));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: CutePalette.pink, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textDark),
                  cursorColor: CutePalette.pink,
                  decoration: const InputDecoration(hintText: "Mulai nulis di sini... Ceritain apa aja, aku dengerin kok :)", hintStyle: TextStyle(color: Color(0xFFCBD5E1)), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 40)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
