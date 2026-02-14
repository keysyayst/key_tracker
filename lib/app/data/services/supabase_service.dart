import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static String? get uid => client.auth.currentUser?.id;
  static bool get signedIn => client.auth.currentSession != null;
}
