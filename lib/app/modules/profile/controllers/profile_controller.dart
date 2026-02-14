import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/supabase_service.dart';

class ProfileController extends GetxController {
  final supabase = SupabaseService.client;
  final _picker = ImagePicker();

  final loading = false.obs;
  final error = RxnString();

  final session = Rxn<Session>();
  bool get isLoggedIn => session.value != null;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final displayNameCtrl = TextEditingController();

  final savedDisplayName = ''.obs;
  final avatarUrl = ''.obs;

  StreamSubscription<AuthState>? _authSub;

  String? get email => supabase.auth.currentUser?.email;

  @override
  void onInit() {
    super.onInit();
    session.value = supabase.auth.currentSession;
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      session.value = data.session;
      if (isLoggedIn) {
        await loadProfile();
      } else {
        savedDisplayName.value = '';
        displayNameCtrl.text = '';
        avatarUrl.value = '';
      }
    });

    if (isLoggedIn) loadProfile();
  }

  // ... (signIn, signUp, signOut tetap sama) ...
  Future<void> signIn() async {
     // (kode sign in kamu sebelumnya)
     // singkatnya:
     final email = emailCtrl.text.trim();
     final password = passwordCtrl.text;
     if (email.isEmpty || password.isEmpty) return;
     loading.value = true;
     try {
       await supabase.auth.signInWithPassword(email: email, password: password);
       Get.snackbar('Login', 'Berhasil login');
     } catch(e) { Get.snackbar('Gagal', e.toString()); }
     finally { loading.value = false; }
  }

  Future<void> signUp() async {
    // (kode sign up kamu sebelumnya)
     final email = emailCtrl.text.trim();
     final password = passwordCtrl.text;
     if (email.isEmpty || password.isEmpty) return;
     loading.value = true;
     try {
       await supabase.auth.signUp(email: email, password: password);
       Get.snackbar('Daftar', 'Cek email konfirmasi');
     } catch(e) { Get.snackbar('Gagal', e.toString()); }
     finally { loading.value = false; }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> loadProfile() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await supabase.from('profiles').select('display_name, avatar_url').eq('id', uid).maybeSingle();
      if (data != null) {
        final name = (data['display_name'] as String?) ?? '';
        savedDisplayName.value = name;
        displayNameCtrl.text = name;
        avatarUrl.value = (data['avatar_url'] as String?) ?? '';
      }
    } catch (_) {}
  }

  // === FUNGSI SIMPAN & TUTUP (PERBAIKAN UTAMA) ===
  Future<void> saveDisplayName() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    final name = displayNameCtrl.text.trim();

    loading.value = true; // Mulai Loading

    try {
      await supabase.from('profiles').upsert({
        'id': uid,
        'display_name': name.isEmpty ? null : name,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      savedDisplayName.value = name;
      
      loading.value = false; // Stop Loading Dulu

      // TUTUP BOTTOM SHEET DARI SINI
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      Get.snackbar('Berhasil', 'Nama profil diperbarui ✨', 
        backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      loading.value = false;
      Get.snackbar('Gagal', 'Tidak bisa menyimpan profil.');
    }
  }

  Future<void> uploadAvatar() async {
     // (kode upload avatar kamu sebelumnya - tidak ada perubahan)
     // ...
     final uid = supabase.auth.currentUser?.id;
     if (uid == null) return;
     try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (image == null) return;
        loading.value = true;
        final file = File(image.path);
        final fileExt = image.path.split('.').last;
        final fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('avatars').upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
        final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
        await supabase.from('profiles').upsert({'id': uid, 'avatar_url': imageUrl, 'updated_at': DateTime.now().toIso8601String()});
        avatarUrl.value = imageUrl;
        Get.snackbar('Keren!', 'Foto profil baru terpasang 📸');
     } catch (e) { Get.snackbar('Gagal', 'Gagal upload.'); } 
     finally { loading.value = false; }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    displayNameCtrl.dispose();
    super.onClose();
  }
}
