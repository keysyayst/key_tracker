import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../controllers/wallet_controller.dart';
import '../../../themes/app_colors.dart';

// --- THEME CONSTANTS ---
class CutePalette {
  static const pink = Color(0xFFFB7185);    // Dominan
  static const softPink = Color(0xFFFFE4E6); // Pengganti warna Biru/Ungu soft
  static const salmon = Color(0xFFFDA4AF);   // Pengganti warna sekunder
  static const emerald = Color(0xFF34D399); // Tetap hijau untuk income
  static const orange = Color(0xFFFB923C);
  static const muted = Color(0xFF94A3B8);
  static const dark = Color(0xFF881337);    // Dark Pink/Red untuk teks header
}

class CuteSurface {
  static const bg = Color(0xFFFFF0F3); // Background Pinkish sangat muda
  static const card = Colors.white;
  static const border = Color(0xFFFECDD3); // Border pink muda
}

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(WalletController()); 

    return Scaffold(
      backgroundColor: CuteSurface.bg,
      appBar: AppBar(
        title: const Text(
          'Dompetku',
          style: TextStyle(fontWeight: FontWeight.w900, color: CutePalette.dark, fontSize: 20),
        ),
        backgroundColor: CuteSurface.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: CutePalette.dark, size: 18),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // CUSTOM TAB BAR (Updated Colors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: CuteSurface.border),
              ),
              child: Obx(() => Row(
                children: [
                  _buildTabButton("Dompet", 0, CutePalette.pink),
                  _buildTabButton("Analisis", 1, CutePalette.salmon),
                ],
              )),
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: CutePalette.pink));
              }
              return IndexedStack(
                index: controller.currentTab.value,
                children: [
                  _buildWalletTab(context),
                  _buildStatsTab(context),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, Color color) {
    bool isActive = controller.currentTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.currentTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : CutePalette.muted,
            ),
          ),
        ),
      ),
    );
  }

  // --- HALAMAN 1: DOMPET (WALLET) ---
  Widget _buildWalletTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.fetchData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotalBalanceCard(balance: controller.totalBalance),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _CuteActionButton(icon: Icons.arrow_downward_rounded, label: 'Pemasukan', color: CutePalette.emerald, onTap: () => _showTransactionDialog(context, false))),
                const SizedBox(width: 16),
                Expanded(child: _CuteActionButton(icon: Icons.arrow_upward_rounded, label: 'Pengeluaran', color: CutePalette.pink, onTap: () => _showTransactionDialog(context, true))),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Sumber Dana', icon: Icons.account_balance_wallet_rounded, color: CutePalette.pink, action: IconButton(icon: const Icon(Icons.add_circle_rounded, color: CutePalette.pink), onPressed: () => _showAddWalletDialog(context))),
            if (controller.wallets.isEmpty) _EmptyState(message: "Belum ada dompet.", onTap: () => _showAddWalletDialog(context))
            else SizedBox(height: 160, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: controller.wallets.length, separatorBuilder: (_, __) => const SizedBox(width: 16), itemBuilder: (ctx, i) => GestureDetector(onTap: () => _showEditWalletDialog(context, controller.wallets[i]), child: WalletCard(wallet: controller.wallets[i])))),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Budget Mingguan', icon: Icons.pie_chart_rounded, color: CutePalette.orange, action: IconButton(icon: const Icon(Icons.edit_rounded, color: CutePalette.orange), onPressed: () => _showBudgetAllocationDialog(context))),
            BudgetCard(limit: controller.weeklyBudgetLimit.value, spent: controller.weeklySpent.value, onTap: () => _showTransactionDialog(context, true)),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Impianku (Tabungan)', icon: Icons.stars_rounded, color: CutePalette.pink, action: IconButton(icon: const Icon(Icons.add_circle_rounded, color: CutePalette.pink), onPressed: () => _showAddSavingDialog(context))),
            if (controller.savingTargets.isEmpty) _EmptyState(message: "Mulai menabung yuk!", onTap: () => _showAddSavingDialog(context))
            else Column(children: controller.savingTargets.map((target) => Padding(padding: const EdgeInsets.only(bottom: 16), child: SavingsTargetCard(target: target))).toList()),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Riwayat', icon: Icons.history_rounded, color: CutePalette.salmon),
            if (controller.transactions.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada transaksi")))
            else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: controller.transactions.length > 5 ? 5 : controller.transactions.length, itemBuilder: (ctx, i) => _TransactionTile(trx: controller.transactions[i])),
          ],
        ),
      ),
    );
  }

  // --- HALAMAN 2: ANALISIS (PIE CHARTS) ---
  Widget _buildStatsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: CuteSurface.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: CuteSurface.border)),
            child: Row(children: [
              _buildChartFilterBtn("Mingguan", 0),
              _buildChartFilterBtn("Bulanan", 1),
            ]),
          ),
          const SizedBox(height: 24),
          
          // PIE CHART PENGELUARAN
          const Text("Analisis Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CutePalette.dark)),
          const SizedBox(height: 12),
          _PieChartCard(
            title: "Pengeluaran Terbesar", 
            data: controller.getPieData(isExpense: true),
            emptyMessage: "Belum ada pengeluaran",
          ),

          const SizedBox(height: 32),

          // PIE CHART PEMASUKAN
          const Text("Analisis Pemasukan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CutePalette.dark)),
          const SizedBox(height: 12),
          _PieChartCard(
            title: "Sumber Pemasukan", 
            data: controller.getPieData(isExpense: false),
            emptyMessage: "Belum ada pemasukan",
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChartFilterBtn(String text, int value) {
    return Expanded(
      child: Obx(() {
        final isActive = controller.chartFilter.value == value;
        return GestureDetector(
          onTap: () => controller.chartFilter.value = value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: isActive ? CutePalette.pink : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.white : CutePalette.muted)),
          ),
        );
      }),
    );
  }

  // --- CUSTOM DIALOGS ---

  void _showAddWalletDialog(BuildContext context) {
    final nameC = TextEditingController();
    final balanceC = TextEditingController();
    _showCuteDialog(context: context, title: "Tambah Dompet", icon: Icons.account_balance_wallet_rounded, color: CutePalette.pink, children: [
      _CuteTextField(controller: nameC, label: "Nama Dompet"),
      const SizedBox(height: 12),
      _CuteTextField(controller: balanceC, label: "Saldo Awal (Rp)", isNumber: true),
    ], onConfirm: () { if (nameC.text.isNotEmpty) { Get.back(); controller.addWallet(nameC.text, double.tryParse(balanceC.text) ?? 0); } });
  }

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    final nameC = TextEditingController(text: wallet.name);
    _showCuteDialog(context: context, title: "Edit Dompet", icon: Icons.edit_rounded, color: CutePalette.pink, children: [
      _CuteTextField(controller: nameC, label: "Nama Dompet"),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: TextButton.icon(onPressed: () { Get.back(); Get.defaultDialog(title: "Hapus?", middleText: "Yakin hapus dompet ini?", textConfirm: "Ya", textCancel: "Batal", confirmTextColor: Colors.white, buttonColor: Colors.red, onConfirm: () { Get.back(); controller.deleteWallet(wallet.id); }); }, icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Hapus Dompet", style: TextStyle(color: Colors.red)))),
    ], onConfirm: () { if (nameC.text.isNotEmpty) { Get.back(); controller.editWallet(wallet.id, nameC.text); } });
  }

  void _showTransactionDialog(BuildContext context, bool isExpense) {
    if (controller.wallets.isEmpty) { Get.snackbar("Ups", "Buat dompet dulu!", backgroundColor: CutePalette.pink, colorText: Colors.white); return; }
    final titleC = TextEditingController(); final amountC = TextEditingController();
    String? selectedWalletId = controller.wallets.first.id;

    Get.bottomSheet(Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Transaksi Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      _CuteTextField(controller: titleC, label: "Judul (Mis: Makan, Gaji)"), const SizedBox(height: 12),
      _CuteTextField(controller: amountC, label: "Nominal", isNumber: true), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: selectedWalletId, items: controller.wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(), onChanged: (v) { if(v!=null) selectedWalletId = v; }, decoration: InputDecoration(filled: true, fillColor: CuteSurface.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isExpense ? CutePalette.pink : CutePalette.emerald, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () { if (amountC.text.isNotEmpty && selectedWalletId != null) { Get.back(); controller.addTransaction(titleC.text, double.tryParse(amountC.text) ?? 0, isExpense, selectedWalletId!); } }, child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
    ])), isScrollControlled: true);
  }

  void _showBudgetAllocationDialog(BuildContext context) {
    if (controller.wallets.isEmpty) { Get.snackbar("Ups", "Buat dompet dulu!", backgroundColor: CutePalette.pink, colorText: Colors.white); return; }
    final budgetC = TextEditingController(text: controller.weeklyBudgetLimit.value > 0 ? controller.weeklyBudgetLimit.value.toStringAsFixed(0) : '');
    String? selectedWalletId = controller.wallets.first.id;

    _showCuteDialog(context: context, title: "Set Budget", icon: Icons.pie_chart, color: CutePalette.orange, children: [
      const Text("Saldo dompet akan dipotong untuk budget.", style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 10),
      _CuteTextField(controller: budgetC, label: "Nominal", isNumber: true), const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: selectedWalletId, items: controller.wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(), onChanged: (v) { if(v!=null) selectedWalletId = v; }, decoration: InputDecoration(filled: true, fillColor: CuteSurface.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    ], onConfirm: () { if (budgetC.text.isNotEmpty && selectedWalletId != null) { Get.back(); controller.setBudgetWithAllocation(double.parse(budgetC.text), selectedWalletId!); } });
  }

  void _showAddSavingDialog(BuildContext context) {
    final titleC = TextEditingController(); final targetC = TextEditingController();
    _showCuteDialog(context: context, title: "Impian Baru", icon: Icons.star, color: CutePalette.pink, children: [
      _CuteTextField(controller: titleC, label: "Nama Impian"), const SizedBox(height: 12),
      _CuteTextField(controller: targetC, label: "Target (Rp)", isNumber: true),
    ], onConfirm: () { if (titleC.text.isNotEmpty) { Get.back(); controller.addSavingTarget(titleC.text, double.tryParse(targetC.text) ?? 0); } });
  }

  void _showEditSavingDialog(BuildContext context, SavingTargetModel target) {
    final titleC = TextEditingController(text: target.title);
    final targetC = TextEditingController(text: target.targetAmount.toStringAsFixed(0));
    _showCuteDialog(context: context, title: "Edit Impian", icon: Icons.edit, color: CutePalette.pink, children: [
      _CuteTextField(controller: titleC, label: "Nama Impian"), const SizedBox(height: 12),
      _CuteTextField(controller: targetC, label: "Target (Rp)", isNumber: true),
      const SizedBox(height: 20),
      TextButton.icon(onPressed: () { Get.back(); controller.deleteSavingTarget(target.id); }, icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Hapus Impian", style: TextStyle(color: Colors.red))),
    ], onConfirm: () { if (titleC.text.isNotEmpty) { Get.back(); controller.editSavingTarget(target.id, titleC.text, double.tryParse(targetC.text) ?? 0); } });
  }

  void _showAddSavingFundDialog(BuildContext context, SavingTargetModel target) {
    final amountC = TextEditingController();
    _showCuteDialog(context: context, title: "Nabung Yuk!", icon: Icons.savings, color: CutePalette.emerald, children: [
      Text("Tambah saldo ke '${target.title}'", style: const TextStyle(fontWeight: FontWeight.bold)),
      const Text("(Tidak mengurangi saldo dompet utama)", style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 16),
      _CuteTextField(controller: amountC, label: "Jumlah (Rp)", isNumber: true),
    ], onConfirm: () { if (amountC.text.isNotEmpty) { Get.back(); controller.updateSavingAmount(target.id, double.tryParse(amountC.text) ?? 0); } });
  }

  void _showCuteDialog({required BuildContext context, required String title, required IconData icon, required Color color, required List<Widget> children, required VoidCallback onConfirm}) {
    showDialog(context: context, builder: (_) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
      const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 24),
      ...children, const SizedBox(height: 24),
      Row(children: [Expanded(child: TextButton(onPressed: () => Get.back(), child: const Text("Batal", style: TextStyle(color: Colors.grey)))), Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: onConfirm, child: const Text("Simpan", style: TextStyle(color: Colors.white))))]),
    ]))));
  }
}

// --- WIDGET COMPONENTS (PIE CHART & OTHERS) ---

class _PieChartCard extends StatelessWidget {
  final String title;
  final List<PieChartData> data;
  final String emptyMessage;

  const _PieChartCard({required this.title, required this.data, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: CuteSurface.border)),
        child: Center(child: Text(emptyMessage, style: const TextStyle(color: CutePalette.muted))),
      );
    }

    double total = data.fold(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: CuteSurface.border), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            children: [
              // 1. CHART
              SizedBox(
                width: 120, height: 120,
                child: CustomPaint(
                  painter: _SimplePiePainter(data: data, total: total),
                ),
              ),
              const SizedBox(width: 20),
              // 2. LEGEND
              Expanded(
                child: Column(
                  children: data.take(4).map((d) {
                    final percent = (d.value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            SizedBox(width: 80, child: Text(d.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: CutePalette.dark))),
                          ]),
                          Text("$percent%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: CutePalette.muted)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _SimplePiePainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;
  _SimplePiePainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    var startRadian = -pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var d in data) {
      final sweepRadian = (d.value / total) * 2 * pi;
      paint.color = d.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRadian, sweepRadian, true, paint);
      startRadian += sweepRadian;
    }
    // Hole in middle (Donut Style)
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class SavingsTargetCard extends StatelessWidget {
  final SavingTargetModel target;
  const SavingsTargetCard({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final double percent = (target.targetAmount > 0) ? (target.currentAmount / target.targetAmount).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => (context.findAncestorWidgetOfExactType<WalletView>() as WalletView)._showEditSavingDialog(context, target),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: CuteSurface.border), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 54, height: 54, child: CircularProgressIndicator(value: percent, strokeWidth: 6, backgroundColor: CuteSurface.bg, color: CutePalette.pink)),
              const Icon(Icons.star_rounded, color: CutePalette.pink, size: 24),
            ]),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(target.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: CutePalette.dark)),
                const SizedBox(height: 6),
                Text('${NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(target.currentAmount)} / ${NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(target.targetAmount)}', style: const TextStyle(color: CutePalette.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: CutePalette.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_rounded, color: CutePalette.emerald),
                onPressed: () => (context.findAncestorWidgetOfExactType<WalletView>() as WalletView)._showAddSavingFundDialog(context, target), 
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget { final String title; final IconData icon; final Color color; final Widget? action; const _SectionHeader({required this.title, required this.icon, required this.color, this.action}); @override Widget build(BuildContext context) => Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: CutePalette.dark))), if (action != null) action!]); }
class _CuteTextField extends StatelessWidget { final TextEditingController controller; final String label; final bool isNumber; const _CuteTextField({required this.controller, required this.label, this.isNumber = false}); @override Widget build(BuildContext context) => TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, style: const TextStyle(fontWeight: FontWeight.w600, color: CutePalette.dark), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: CutePalette.muted, fontSize: 14), filled: true, fillColor: CuteSurface.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))); }
class _TotalBalanceCard extends StatelessWidget { final double balance; const _TotalBalanceCard({required this.balance}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Total Saldo Kamu', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))), const SizedBox(height: 12), Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(balance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))])); }
class _CuteActionButton extends StatelessWidget { final IconData icon; final String label; final Color color; final VoidCallback onTap; const _CuteActionButton({required this.icon, required this.label, required this.color, required this.onTap}); @override Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1), width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 12), Text(label, style: const TextStyle(color: CutePalette.dark, fontWeight: FontWeight.w700, fontSize: 13))])))); }
class _EmptyState extends StatelessWidget { final String message; final VoidCallback onTap; const _EmptyState({required this.message, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: CuteSurface.border, width: 2)), child: Column(children: [const Icon(Icons.add_circle_outline_rounded, size: 32, color: CutePalette.muted), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: CutePalette.muted, fontWeight: FontWeight.w600))]))); }
class WalletCard extends StatelessWidget { final WalletModel wallet; const WalletCard({super.key, required this.wallet}); @override Widget build(BuildContext context) => Container(width: 150, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: CuteSurface.border), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color(wallet.colorValue).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(IconData(wallet.iconCode, fontFamily: 'MaterialIcons'), color: Color(wallet.colorValue), size: 20)), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(wallet.name, style: const TextStyle(color: CutePalette.muted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(wallet.balance), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: CutePalette.dark))])])); }
class BudgetCard extends StatelessWidget { final double limit; final double spent; final VoidCallback onTap; const BudgetCard({super.key, required this.limit, required this.spent, required this.onTap}); @override Widget build(BuildContext context) { if (limit == 0) return _EmptyState(message: "Atur budget mingguan biar hemat!", onTap: onTap); final double percent = (spent / limit).clamp(0.0, 1.0); final Color barColor = percent > 0.9 ? CutePalette.pink : (percent > 0.7 ? CutePalette.orange : CutePalette.emerald); return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: CuteSurface.border), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Terpakai', style: TextStyle(color: CutePalette.muted, fontWeight: FontWeight.w600)), Text('${(percent * 100).toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontWeight: FontWeight.w900))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: percent, minHeight: 10, backgroundColor: CuteSurface.bg, color: barColor)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(spent), style: const TextStyle(fontWeight: FontWeight.w800, color: CutePalette.dark)), Text('dari ${NumberFormat.compact(locale: 'id').format(limit)}', style: const TextStyle(color: CutePalette.muted, fontSize: 12))])]))); } }
class _TransactionTile extends StatelessWidget { final TransactionModel trx; const _TransactionTile({required this.trx}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: CuteSurface.border)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (trx.isExpense ? CutePalette.pink : CutePalette.emerald).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(trx.isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: trx.isExpense ? CutePalette.pink : CutePalette.emerald, size: 20)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(trx.title, style: const TextStyle(fontWeight: FontWeight.w700, color: CutePalette.dark)), const SizedBox(height: 4), Text(DateFormat('d MMM, HH:mm').format(trx.date), style: const TextStyle(fontSize: 12, color: CutePalette.muted))])), Text(NumberFormat.currency(locale: 'id', symbol: trx.isExpense ? '-Rp ' : '+Rp ', decimalDigits: 0).format(trx.amount), style: TextStyle(color: trx.isExpense ? CutePalette.pink : CutePalette.emerald, fontWeight: FontWeight.w800))])); }
