import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sello/models/education_guide.dart';
import 'package:sello/models/education_quota.dart';
import 'package:sello/models/report_period.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/services/report_service.dart';

class EducationException implements Exception {
  const EducationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EducationLoadResult {
  const EducationLoadResult({
    required this.guide,
    required this.quota,
  });

  final EducationGuide guide;
  final EducationQuota quota;
}

class EducationService {
  EducationService._();

  static final EducationService instance = EducationService._();

  static const _defaultDailyLimit = EducationQuota.proDailyLimit;

  final _reportService = ReportService.instance;
  final _productService = ProductService.instance;
  final _aiService = AiService.instance;

  Future<EducationQuota> getQuota(
    String userId, {
    int dailyLimit = _defaultDailyLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_usageKey(userId)) ?? 0;
    final limit = dailyLimit.clamp(1, 99);
    return EducationQuota(used: used.clamp(0, limit), limit: limit);
  }

  /// Muat tips hari ini tanpa menambah kuota (pakai cache bila ada).
  Future<EducationLoadResult> loadCachedOrInitial(
    String userId, {
    int dailyLimit = _defaultDailyLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs, userId);

    final cached = _readCachedGuide(prefs, userId);
    if (cached != null) {
      return EducationLoadResult(
        guide: cached,
        quota: await getQuota(userId, dailyLimit: dailyLimit),
      );
    }

    // Belum ada tips hari ini: generate sekali dan hitung 1 kuota.
    return regenerate(userId, dailyLimit: dailyLimit);
  }

  /// Ganti tips (tombol). Batas mengikuti paket (Gratis 1x, Pro 3x).
  Future<EducationLoadResult> regenerate(
    String userId, {
    int dailyLimit = _defaultDailyLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs, userId);

    final limit = dailyLimit.clamp(1, 99);
    final used = prefs.getInt(_usageKey(userId)) ?? 0;
    if (used >= limit) {
      final cached = _readCachedGuide(prefs, userId);
      throw EducationException(
        cached == null
            ? 'Batas harian tips edukasi sudah habis ($used/$limit). '
                'Coba lagi besok atau upgrade ke Pro.'
            : 'Batas ganti tips hari ini sudah habis ($used/$limit). '
                'Tips saat ini tetap bisa dibaca. Coba lagi besok atau upgrade ke Pro.',
      );
    }

    final guide = await _generateGuide(userId);
    final nextUsed = used + 1;
    await prefs.setInt(_usageKey(userId), nextUsed);
    await prefs.setString(_guideKey(userId), _encodeGuide(guide));
    await prefs.setString(_dayStampKey(userId), _todayStamp());

    return EducationLoadResult(
      guide: guide,
      quota: EducationQuota(used: nextUsed, limit: limit),
    );
  }

  Future<EducationGuide> _generateGuide(String userId) async {
    final now = DateTime.now();
    final range = ReportDateRange.customInclusive(
      from: now.subtract(const Duration(days: 29)),
      to: now,
    );

    try {
      final report = await _reportService.fetchReport(
        userId: userId,
        period: ReportPeriod.custom,
        customRange: range,
        includeInsight: false,
      );
      final products = await _productService.fetchProducts(userId);
      final lowStockCount = products.where((p) => p.stock <= 5).length;

      final fallback = _localGuide(
        reportRevenue: report.totalRevenue,
        reportProfit: report.totalProfit,
        transactions: report.transactionCount,
        lowStockCount: lowStockCount,
        catalogCount: products.length,
        variationSeed: DateTime.now().millisecondsSinceEpoch,
      );

      if (report.transactionCount == 0 || !_aiService.isConfigured) {
        return fallback;
      }

      try {
        return await _aiService.generateEducationTips(
          periodLabel: '30 hari terakhir',
          totalRevenue: report.totalRevenue,
          totalProfit: report.totalProfit,
          transactionCount: report.transactionCount,
          unitsSold: report.unitsSold,
          lowStockCount: lowStockCount,
          topProducts: report.topProducts
              .take(3)
              .map(
                (p) =>
                    '${p.productName}: penjualan Rp ${p.revenue}, '
                    '${p.quantitySold} item',
              )
              .toList(),
          topCustomers: report.topCustomers
              .take(3)
              .map(
                (c) =>
                    '${c.customerName}: ${c.transactionCount} transaksi, '
                    'Rp ${c.revenue}',
              )
              .toList(),
        );
      } catch (_) {
        return fallback;
      }
    } on ReportException catch (e) {
      throw EducationException(e.message);
    } on ProductException catch (e) {
      throw EducationException(e.message);
    } catch (_) {
      throw const EducationException(
        'Gagal memuat edukasi. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<void> _resetIfNewDay(SharedPreferences prefs, String userId) async {
    final stamp = prefs.getString(_dayStampKey(userId));
    final today = _todayStamp();
    if (stamp == today) return;
    await prefs.setInt(_usageKey(userId), 0);
    await prefs.remove(_guideKey(userId));
    await prefs.setString(_dayStampKey(userId), today);
  }

  EducationGuide? _readCachedGuide(SharedPreferences prefs, String userId) {
    final raw = prefs.getString(_guideKey(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _guideFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  String _encodeGuide(EducationGuide guide) {
    return jsonEncode({
      'headline': guide.headline,
      'generated_at': guide.generatedAt.toIso8601String(),
      'tips': guide.tips
          .map(
            (tip) => {
              'title': tip.title,
              'body': tip.body,
              'action_hint': tip.actionHint,
            },
          )
          .toList(),
    });
  }

  EducationGuide _guideFromJson(Map<String, dynamic> json) {
    final tipsRaw = json['tips'];
    final tips = tipsRaw is List
        ? tipsRaw
              .whereType<Map<String, dynamic>>()
              .map(EducationTip.fromJson)
              .toList()
        : <EducationTip>[];
    return EducationGuide(
      headline: (json['headline'] as String?)?.trim().isNotEmpty == true
          ? (json['headline'] as String).trim()
          : 'Tips edukasi',
      tips: tips,
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String _usageKey(String userId) => 'education_usage_$userId';
  String _guideKey(String userId) => 'education_guide_$userId';
  String _dayStampKey(String userId) => 'education_day_$userId';

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  EducationGuide _localGuide({
    required int reportRevenue,
    required int reportProfit,
    required int transactions,
    required int lowStockCount,
    required int catalogCount,
    required int variationSeed,
  }) {
    final pool = <EducationTip>[
      if (transactions == 0)
        const EducationTip(
          title: 'Mulai catat di Kasir',
          body:
              'Belum ada transaksi 30 hari terakhir. '
              'Pakai kasir suara atau scan di aplikasi Sello supaya laporan terisi.',
          actionHint: 'Buka tab Kasir, catat minimal 1 penjualan hari ini.',
        )
      else
        EducationTip(
          title: 'Pakai Laporan di Sello',
          body:
              '30 hari terakhir: $transactions transaksi, '
              'penjualan Rp ${_format(reportRevenue)}, laba Rp ${_format(reportProfit)}.',
          actionHint: 'Buka tab Laporan, filter periode, cek produk terlaris.',
        ),
      if (catalogCount == 0)
        const EducationTip(
          title: 'Daftarkan produk dulu',
          body:
              'Katalog masih kosong. Daftarkan produk lengkap (harga jual, modal, foto) di Sello.',
          actionHint: 'Buka Menu → Produk → Daftar Produk.',
        )
      else if (lowStockCount > 0)
        EducationTip(
          title: 'Stok menipis di katalog',
          body:
              'Ada $lowStockCount produk stok menipis. '
              'Update stok di katalog Sello supaya penjualan tidak terhenti.',
          actionHint: 'Buka Menu → Produk, cek item yang stoknya di bawah 5.',
        )
      else
        const EducationTip(
          title: 'Lengkapi modal produk',
          body:
              'Isi harga modal saat daftar produk di Sello '
              'supaya laba di Laporan lebih akurat.',
          actionHint: 'Buka Menu → Produk, pastikan harga modal terisi.',
        ),
      const EducationTip(
        title: 'Catat nama pelanggan',
        body:
            'Isi nama pelanggan di kasir Sello biar bagian '
            'Pelanggan utama di Laporan lebih berguna.',
        actionHint: 'Saat simpan penjualan di Kasir, isi Nama pelanggan.',
      ),
      const EducationTip(
        title: 'Coba kasir suara singkat',
        body:
            'Ucapkan penjualan singkat di Kasir, lalu cocokkan ke katalog otomatis.',
        actionHint: 'Buka tab Kasir mode Suara, ketuk mikrofon.',
      ),
      const EducationTip(
        title: 'Pakai scan produk',
        body:
            'Scan foto produk yang sudah ada di katalog supaya pencatatan lebih cepat.',
        actionHint: 'Buka Kasir mode Scan, lalu deteksi produk.',
      ),
    ];

    final start = variationSeed % pool.length;
    final rotated = [
      ...pool.sublist(start),
      ...pool.sublist(0, start),
    ];

    return EducationGuide(
      headline: transactions == 0
          ? 'Mulai dari Kasir Sello biar tipsnya lebih pas'
          : 'Tips singkat memakai fitur di aplikasi Sello',
      tips: rotated.take(3).toList(),
      generatedAt: DateTime.now(),
    );
  }

  String _format(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
