import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sello/core/config/env.dart';

abstract final class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      // Firebase Auth JWT → Supabase RLS (auth.uid() = Firebase UID).
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
