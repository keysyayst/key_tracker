import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/pastel_card.dart';
import '../../../widgets/settings_tile.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgRose,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Obx(() {
            return controller.isLoggedIn ? _accountUI(context) : _loginUI();
          }),
        ),
      ),
    );
  }

  Widget _loginUI() {
    // (Kode login UI sama persis dengan sebelumnya)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        PastelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login dulu ya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: controller.emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded, size: 20))),
              const SizedBox(height: 10),
              TextField(controller: controller.passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_rounded, size: 20))),
              const SizedBox(height: 14),
              Obx(() {
                final loading = controller.loading.value;
                return Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: loading ? null : controller.signIn, style: ElevatedButton.styleFrom(backgroundColor: AppColors.pink500, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.symmetric(vertical: 14)), child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login', style: TextStyle(fontWeight: FontWeight.w900)))),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: loading ? null : controller.signUp, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)), child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w900))),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final e = controller.error.value;
                if (e == null) return const SizedBox.shrink();
                return Text(e, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),

        PastelCard(
          child: Row(
            children: [
              GestureDetector(
                onTap: controller.uploadAvatar,
                child: Stack(
                  children: [
                    Obx(() {
                      final url = controller.avatarUrl.value;
                      return Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF3F4F6), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)], image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null),
                        child: url.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF9CA3AF), size: 30) : null,
                      );
                    }),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.pink500, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Obx(() {
                  final name = controller.savedDisplayName.value.trim().isEmpty ? 'Hai, Teman!' : controller.savedDisplayName.value.trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(controller.email ?? '-', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      InkWell(onTap: _openEditProfileSheet, child: const Text('Edit Nama', style: TextStyle(color: AppColors.pink500, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        // (Menu settings sama seperti sebelumnya)
        // ... (Singkat untuk menghemat space, tapi pakai kode lengkapmu yg tadi untuk bagian bawah ini)
        const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        PastelCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          child: Column(
            children: [
              SettingsTile(icon: Icons.notifications_active_rounded, title: 'Reminder', trailing: Switch(value: true, onChanged: (val) => Get.snackbar('Reminder', val ? 'Diaktifkan' : 'Dimatikan', duration: const Duration(seconds: 1)), activeColor: AppColors.pink500), onTap: () {}),
              _divider(),
              SettingsTile(icon: Icons.lock_rounded, title: 'App Lock', onTap: () => _showSimpleDialog(context, 'App Lock', 'Fitur keamanan ini akan segera hadir!')),
              _divider(),
              SettingsTile(icon: Icons.download_rounded, title: 'Export Data (PDF/Excel)', onTap: () => _showSimpleDialog(context, 'Export', 'Fitur export data ke PDF sedang dikerjakan.')),
              _divider(),
              SettingsTile(icon: Icons.restore_rounded, title: 'Restore Data', onTap: () => _showSimpleDialog(context, 'Restore', 'Kamu bisa mengembalikan data lama di versi berikutnya.')),
              _divider(),
              SettingsTile(icon: Icons.logout_rounded, title: 'Logout', iconColor: Colors.redAccent, textColor: Colors.redAccent, onTap: () => _showLogoutConfirm()),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(child: Text('Key Tracker v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 10))),
      ],
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 0.5, color: Colors.grey[200], indent: 50, endIndent: 10);
  void _showSimpleDialog(BuildContext context, String title, String msg) { showDialog(context: context, builder: (c) => AlertDialog(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), content: Text(msg), actions: [TextButton(onPressed: () => Get.back(), child: const Text('Oke'))])); }
  void _showLogoutConfirm() { Get.defaultDialog(title: 'Logout', middleText: 'Yakin ingin keluar akun?', textConfirm: 'Ya, Keluar', textCancel: 'Batal', confirmTextColor: Colors.white, buttonColor: Colors.redAccent, onConfirm: () { Get.back(); controller.signOut(); }); }

  // === INI BAGIAN UTAMA YANG DIPERBAIKI ===
  void _openEditProfileSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              const Text('Ganti Nama Tampilan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(
                controller: controller.displayNameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Panggilan',
                  filled: true,
                  fillColor: AppColors.bgRose,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              
              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  // Kita pakai Obx HANYA untuk update tampilan tombol (Loading/Text)
                  // Tapi jangan matikan tombol (jangan set null)
                  final loading = controller.loading.value;
                  
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    // Jika loading, tombol tidak melakukan apa-apa tapi TIDAK null (agar tidak kehilangan fokus)
                    onPressed: loading 
                        ? () {} // Dummy function saat loading
                        : controller.saveDisplayName, // Panggil controller langsung
                    
                    child: loading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w900)),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      // Tambahkan ini biar kalau user tap di luar, controller tau dan reset state jika perlu
      isScrollControlled: true, 
    );
  }
}
