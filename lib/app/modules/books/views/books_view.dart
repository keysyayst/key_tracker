import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../themes/app_colors.dart';
import '../controllers/books_controller.dart';
import '../../../data/models/book_model.dart';

class BooksView extends GetView<BooksController> {
  const BooksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgRose,
      resizeToAvoidBottomInset: false, // Mencegah keyboard merusak layout
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showAddBookDialog(context),
          backgroundColor: AppColors.pink500,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // LAYER 1: RAK
            Column(
              children: [
                _header(),
                Expanded(child: Obx(() => _buildShelves(controller.books))),
              ],
            ),

            // LAYER 2: OVERLAY
            Obx(() {
               if (controller.selectedBook.value != null) {
                 return Positioned.fill(
                   child: GestureDetector(
                     onTap: controller.closeSidePanel,
                     child: Container(color: Colors.black.withOpacity(0.3)),
                   ),
                 );
               }
               return const SizedBox.shrink();
            }),

            // LAYER 3: SIDE PANEL
            Obx(() => AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: 0, bottom: 0,
              right: controller.selectedBook.value != null ? 0 : -350,
              width: 320,
              child: _buildSidePanel(context),
            )),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
           Text('My Library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildShelves(List<BookModel> books) {
    // Pakai ListView biasa dengan itemExtent untuk performa lebih baik
    int rows = (books.length / 3).ceil();
    if (rows < 6) rows = 6;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: rows,
      // itemExtent: 180, // Opsional: Aktifkan jika tinggi rak fix (meningkatkan performa drastis)
      itemBuilder: (context, index) {
        int start = index * 3;
        List<BookModel?> items = [];
        for (int i = 0; i < 3; i++) {
          if (start + i < books.length) items.add(books[start + i]);
          else items.add(null);
        }
        return _shelfRow(items);
      },
    );
  }

  Widget _shelfRow(List<BookModel?> items) {
    return Column(
      children: [
        Container(
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((b) => _bookItem(b)).toList(),
          ),
        ),
        // Visual Rak
        Container(
          height: 14,
          margin: const EdgeInsets.only(bottom: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: AppColors.pink500.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 4))],
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade200],
              begin: Alignment.topCenter, end: Alignment.bottomCenter
            )
          ),
          child: Container(margin: const EdgeInsets.only(top: 12), color: AppColors.pink500.withOpacity(0.2)),
        )
      ],
    );
  }

  Widget _bookItem(BookModel? book) {
    if (book == null) return const SizedBox(width: 85);
    
    return GestureDetector(
      onTap: () => controller.selectBook(book),
      child: Container(
        width: 85, height: 125,
        decoration: BoxDecoration(
          color: AppColors.pink500,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(2, 2))],
          image: (book.coverUrl != null) ? DecorationImage(
            image: NetworkImage(book.coverUrl!), 
            fit: BoxFit.cover
          ) : null,
        ),
        child: book.coverUrl == null 
          ? Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(book.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 3))) 
          : null,
      ),
    );
  }

  // === SIDE PANEL & SLIDER ===
  Widget _buildSidePanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Obx(() {
        final book = controller.selectedBook.value;
        if (book == null) return const SizedBox.shrink();

        final total = book.totalPages ?? 200;
        // PENTING: Ambil nilai slider dari variable khusus di controller
        final currentVal = controller.currentSliderValue.value;
        final percent = (total > 0) ? (currentVal / total).clamp(0.0, 1.0) : 0.0;

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Book Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: controller.closeSidePanel, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            
            // Konten Scrollable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  // Gambar Besar
                  Center(
                    child: Container(
                      height: 180, width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.pink500,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                        image: (book.coverUrl != null) ? DecorationImage(image: NetworkImage(book.coverUrl!), fit: BoxFit.cover) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(book.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(book.author ?? '-', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 24),
                  
                  // Progress Circle
                  CircularPercentIndicator(
                    radius: 60, lineWidth: 10, percent: percent,
                    center: Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    progressColor: AppColors.pink500,
                    backgroundColor: AppColors.pink500.withOpacity(0.1),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),

                  const SizedBox(height: 30),
                  
                  // Slider Logic
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Halaman:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${currentVal.toInt()} / $total'),
                    ],
                  ),
                  Slider(
                    value: currentVal,
                    min: 0,
                    max: total.toDouble(),
                    activeColor: AppColors.pink500,
                    onChanged: (val) {
                      // Update UI Saja (Cepat)
                      controller.currentSliderValue.value = val;
                    },
                    onChangeEnd: (val) {
                      // Update DB Saat Dilepas
                      controller.saveProgress(val.toInt());
                    },
                  ),

                  const SizedBox(height: 20),
                  // Quotes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Obx(() => Text('"${controller.currentQuote.value}"', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic))),
                  ),

                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Hapus Buku', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  )
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.defaultDialog(
      title: 'Hapus?', middleText: 'Buku ini akan dihapus permanen.',
      textConfirm: 'Ya', textCancel: 'Batal',
      confirmTextColor: Colors.white, buttonColor: Colors.red,
      onConfirm: () { Get.back(); controller.deleteSelectedBook(); }
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleC = TextEditingController();
    final authorC = TextEditingController();
    final pageC = TextEditingController();
    final rxFile = Rxn<File>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Buku', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50); // Kompresi Gambar
                    if (img != null) rxFile.value = File(img.path);
                  },
                  child: Center(
                    child: Obx(() => Container(
                      height: 120, width: 90,
                      color: Colors.grey[200],
                      child: rxFile.value != null 
                        ? Image.file(rxFile.value!, fit: BoxFit.cover) 
                        : const Icon(Icons.add_a_photo, color: Colors.grey),
                    )),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: authorC, decoration: const InputDecoration(labelText: 'Penulis', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: pageC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Halaman', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.loading.value ? null : () {
                      if (titleC.text.isEmpty) return;
                      controller.addBookWithCover(
                        title: titleC.text,
                        author: authorC.text,
                        totalPages: int.tryParse(pageC.text) ?? 200,
                        coverFile: rxFile.value
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.pink500, padding: const EdgeInsets.all(16)),
                    child: controller.loading.value ? const Text('Menyimpan...') : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                )
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
