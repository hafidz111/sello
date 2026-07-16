import 'package:shared_preferences/shared_preferences.dart';
import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/models/subscription_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  static const _table = 'user_subscriptions';
  static const _cachePrefix = 'subscription_plan_';

  SupabaseClient get _client => SupabaseConfig.client;

  String _cacheKey(String userId) => '$_cachePrefix$userId';

  /// Ambil paket dari Supabase. Buat baris Gratis jika belum ada.
  /// Cache lokal dipakai sebagai cadangan singkat jika offline.
  Future<SubscriptionPlan> loadPlan(String userId) async {
    try {
      final row = await _client
          .from(_table)
          .select('plan')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        await _upsertPlan(userId: userId, plan: SubscriptionPlan.free);
        await _writeCache(userId, SubscriptionPlan.free);
        return SubscriptionPlan.free;
      }

      final plan = SubscriptionPlan.fromId(row['plan'] as String?);
      await _writeCache(userId, plan);
      return plan;
    } on PostgrestException catch (e) {
      final cached = await _readCache(userId);
      if (cached != null) return cached;
      throw SubscriptionException(_mapDbError(e));
    } catch (_) {
      final cached = await _readCache(userId);
      if (cached != null) return cached;
      throw const SubscriptionException(
        'Gagal memuat paket langganan. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<void> savePlan({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    try {
      await _upsertPlan(userId: userId, plan: plan);
      await _writeCache(userId, plan);
    } on PostgrestException catch (e) {
      throw SubscriptionException(_mapDbError(e));
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      throw const SubscriptionException(
        'Gagal menyimpan paket langganan. Coba lagi nanti.',
      );
    }
  }

  Future<void> _upsertPlan({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    await _client.from(_table).upsert({
      'user_id': userId,
      'plan': plan.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<SubscriptionPlan?> _readCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null) return null;
    return SubscriptionPlan.fromId(raw);
  }

  Future<void> _writeCache(String userId, SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(userId), plan.id);
  }

  String _mapDbError(PostgrestException e) {
    final message = e.message.toLowerCase();
    if (message.contains('permission') || message.contains('policy')) {
      return 'Akses paket ditolak. Coba login ulang.';
    }
    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Tabel paket belum tersedia di server. Jalankan migrasi Supabase dulu.';
    }
    return 'Gagal memproses paket langganan. Coba lagi nanti.';
  }
}
