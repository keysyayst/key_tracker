import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/book_model.dart';
import '../../../data/services/supabase_service.dart';

class BooksController extends GetxController {
  final supabase = SupabaseService.client;
  
  final loading = false.obs;
  final books = <BookModel>[].obs;
  final selectedBook = Rxn<BookModel>(); 
  final currentSliderValue = 0.0.obs; 
  final currentQuote = "".obs;

  final quotes = [
    "So many books, so little time.",
    "A room without books is like a body without a soul.",
    "Books are a uniquely portable magic.",
    "Today a reader, tomorrow a leader."
  ];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadBooks();
    });
    currentQuote.value = (quotes..shuffle()).first;
  }

  // Helper UID
  String? get _uid => supabase.auth.currentUser?.id;

  // === LOAD DATA ===
  Future<void> loadBooks() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      if (books.isEmpty) loading.value = true;

      final response = await supabase
          .from('books')
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);

      final list = (response as List)
          .map((e) => BookModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      books.assignAll(list);
      
      // Refresh selected book data
      if (selectedBook.value != null) {
        final freshBook = list.firstWhereOrNull((b) => b.id == selectedBook.value!.id);
        if (freshBook != null) {
          selectedBook.value = freshBook; 
        } else {
          closeSidePanel();
        }
      }
    } catch (e) {
      print("LOAD ERROR: $e");
    } finally {
      loading.value = false;
    }
  }

  void selectBook(BookModel book) {
    selectedBook.value = book;
    currentSliderValue.value = book.currentPage.toDouble();
    currentQuote.value = (quotes..shuffle()).first;
  }

  void closeSidePanel() {
    selectedBook.value = null;
  }

  // === SAVE PROGRESS ===
  Future<void> saveProgress(int newPage) async {
    final b = selectedBook.value;
    final uid = _uid;
    if (b == null || uid == null) return;

    // Optimistic UI Update
    currentSliderValue.value = newPage.toDouble();

    try {
      String status = b.status;
      final total = b.totalPages ?? 100;
      if (newPage >= total) status = 'finished';
      else if (newPage > 0) status = 'reading';

      // DEBUG: Print ID untuk memastikan bukan "0" lagi
      print("Updating Book ID: ${b.id} to Page: $newPage");

      await supabase.from('books').update({
        'current_page': newPage,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', b.id); // ID sekarang String (UUID), jadi pasti cocok

      // Reload silent
      loadBooks(); 

    } catch (e) {
      Get.snackbar('Error', 'Gagal update: $e', backgroundColor: Colors.red, colorText: Colors.white);
      print("UPDATE ERROR: $e");
    }
  }

  // === ADD BOOK ===
  Future<void> addBookWithCover({
    required String title,
    required String author,
    required int totalPages,
    File? coverFile,
  }) async {
    final uid = _uid;
    if (uid == null) {
      Get.snackbar('Error', 'Sesi habis, login ulang.');
      return;
    }

    loading.value = true;

    try {
      String? coverUrl;
      if (coverFile != null) {
        final fileExt = coverFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final fullPath = '$uid/$fileName';
        
        try {
           await supabase.storage.from('book_covers').upload(fullPath, coverFile);
           coverUrl = supabase.storage.from('book_covers').getPublicUrl(fullPath);
        } catch (_) {}
      }

      await supabase.from('books').insert({
        'user_id': uid,
        'title': title,
        'author': author,
        'status': 'reading',
        'total_pages': totalPages,
        'current_page': 0,
        'cover_url': coverUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (Get.isBottomSheetOpen == true) Get.back();
      Get.snackbar('Sukses', 'Buku ditambahkan', backgroundColor: Colors.green, colorText: Colors.white);
      await loadBooks();

    } catch (e) {
      Get.snackbar('Gagal', '$e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      loading.value = false;
    }
  }

  // === DELETE BOOK ===
  Future<void> deleteSelectedBook() async {
    final b = selectedBook.value;
    if (b == null) return;

    try {
      final tempId = b.id;
      closeSidePanel();
      books.removeWhere((x) => x.id == tempId);

      await supabase.from('books').delete().eq('id', tempId);
      
      Get.snackbar('Terhapus', 'Buku dihapus', backgroundColor: Colors.red, colorText: Colors.white);
      loadBooks();
    } catch (e) {
      loadBooks();
      Get.snackbar('Gagal Hapus', '$e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
