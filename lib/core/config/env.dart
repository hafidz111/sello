import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Environment tidak ditemukan.'
      );
    }
    return value;
  }

  static String get supabaseUrl => _require('SUPABASE_URL');

  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
}
