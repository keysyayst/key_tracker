import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/routes/app_pages.dart';
import 'app/themes/app_theme.dart';

// === TAMBAHAN 1: Import ProfileController ===
// (Sesuaikan path folder jika berbeda)
import 'app/modules/profile/controllers/profile_controller.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Ini yang memperbaiki LocaleDataException untuk DateFormat 'id_ID'
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // === TAMBAHAN 2: Inject ProfileController ===
  // Kita taruh di sini agar controllernya aktif terus (permanent: true)
  // dan bisa diakses oleh Dashboard kapan saja.
  Get.put(ProfileController(), permanent: true);

  runApp(const KeyTrackerApp());
}

class KeyTrackerApp extends StatelessWidget {
  const KeyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Key Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,

      // aktifkan localization delegates + locale Indonesia
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
