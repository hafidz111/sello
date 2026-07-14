import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/models/business_report.dart';
import 'package:sello/models/customer_sales_summary.dart';
import 'package:sello/models/product_sales_summary.dart';
import 'package:sello/models/report_period.dart';
import 'package:sello/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportException implements Exception {
  const ReportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  static const _topLimit = 5;
  static const _walkInCustomer = 'Pelanggan umum';

  final _aiService = AiService.instance;

  SupabaseClient get _client => SupabaseConfig.client;

  Future<BusinessReport> fetchReport({
    required String userId,
    required ReportPeriod period,
    ReportDateRange? customRange,
  }) async {
    final range = period == ReportPeriod.custom
        ? (customRange ?? ReportDateRange.forPeriod(ReportPeriod.custom))
        : ReportDateRange.forPeriod(period);

    try {
      final rows = await _fetchSalesRows(
        userId: userId,
        from: range.start,
        toExclusive: range.endExclusive,
      );
      final aggregated = _aggregate(rows);
      final periodLabel = period == ReportPeriod.custom
          ? _formatRangeLabel(range.start, range.endInclusive)
          : period.label;

      final fallBackInsight = _buildLocalInsight(
        periodLabel: periodLabel,
        totalRevenue: aggregated.totalRevenue,
        totalProfit: aggregated.totalProfit,
        transactionCount: aggregated.transactionCount,
        unitsSold: aggregated.unitsSold,
        topProducts: aggregated.topProducts,
        topCustomers: aggregated.topCustomers,
      );

      var insight = fallBackInsight;
      if (_aiService.isConfigured && aggregated.transactionCount > 0) {
        try {
          insight = await _aiService.summarizeBusinessReport(
            periodLabel: periodLabel,
            totalRevenue: aggregated.totalRevenue,
            totalProfit: aggregated.totalProfit,
            transactionCount: aggregated.transactionCount,
            unitsSold: aggregated.unitsSold,
            topProducts: aggregated.topProducts
                .map(
                  (p) =>
                      '${p.productName}: penjualan Rp ${p.revenue}, '
                      'laba Rp ${p.profit}, ${p.transactionCount} transaksi, '
                      '${p.quantitySold} item',
                )
                .toList(),
            topCustomers: aggregated.topCustomers
                .map(
                  (c) =>
                      '${c.customerName}: penjualan Rp ${c.revenue}, '
                      'laba Rp ${c.profit}, ${c.transactionCount} transaksi, '
                      '${c.quantitySold} item',
                )
                .toList(),
          );
        } catch (_) {
          insight = fallBackInsight;
        }
      }

      return BusinessReport(
        period: period,
        rangeStart: range.start,
        rangeEndInclusive: range.endInclusive,
        totalRevenue: aggregated.totalRevenue,
        totalProfit: aggregated.totalProfit,
        transactionCount: aggregated.transactionCount,
        unitsSold: aggregated.unitsSold,
        topProducts: aggregated.topProducts,
        topCustomers: aggregated.topCustomers,
        insight: insight,
      );
    } on PostgrestException catch (e) {
      throw ReportException(_mapDbError(e));
    } catch (_) {
      throw const ReportException(
        'Gagal memuat laporan. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSalesRows({
    required String userId,
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final rows = await _client
        .from('sales')
        .select(
          'id, product_id, quantity, unit_price, unit_cost, total, '
          'customer_name, created_at, products(name)',
        )
        .eq('user_id', userId)
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', toExclusive.toUtc().toIso8601String())
        .order('created_at', ascending: false);

    return (rows as List).whereType<Map<String, dynamic>>().toList();
  }

  ({
    int totalRevenue,
    int totalProfit,
    int transactionCount,
    int unitsSold,
    List<ProductSalesSummary> topProducts,
    List<CustomerSalesSummary> topCustomers,
  })
  _aggregate(List<Map<String, dynamic>> rows) {
    var totalRevenue = 0;
    var totalProfit = 0;
    var unitsSold = 0;
    final byProduct = <String, _MutableAgg>{};
    final byCustomer = <String, _MutableAgg>{};

    for (final row in rows) {
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      final unitCost = (row['unit_cost'] as num?)?.toInt() ?? 0;
      final profit = total - (unitCost * qty);
      final productId = row['product_id'] as String? ?? '';
      final productName = _readProductName(row);
      final customerName = _readCustomerName(row);

      totalRevenue += total;
      totalProfit += profit;
      unitsSold += qty;

      final product = byProduct.putIfAbsent(
        productId,
        () => _MutableAgg(key: productId, label: productName),
      );
      product.revenue += total;
      product.profit += profit;
      product.transactionCount += 1;
      product.quantitySold += qty;

      final customer = byCustomer.putIfAbsent(
        customerName,
        () => _MutableAgg(key: customerName, label: customerName),
      );
      customer.revenue += total;
      customer.profit += profit;
      customer.transactionCount += 1;
      customer.quantitySold += qty;
    }

    List<_MutableAgg> sorted(Iterable<_MutableAgg> values) {
      final list = values.toList()
        ..sort((a, b) {
          final byRevenue = b.revenue.compareTo(a.revenue);
          if (byRevenue != 0) return byRevenue;
          return b.quantitySold.compareTo(a.quantitySold);
        });
      return list;
    }

    return (
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      transactionCount: rows.length,
      unitsSold: unitsSold,
      topProducts: sorted(byProduct.values)
          .take(_topLimit)
          .map(
            (p) => ProductSalesSummary(
              productId: p.key,
              productName: p.label,
              revenue: p.revenue,
              profit: p.profit,
              transactionCount: p.transactionCount,
              quantitySold: p.quantitySold,
            ),
          )
          .toList(),
      topCustomers: sorted(byCustomer.values)
          .take(_topLimit)
          .map(
            (c) => CustomerSalesSummary(
              customerName: c.label,
              revenue: c.revenue,
              profit: c.profit,
              transactionCount: c.transactionCount,
              quantitySold: c.quantitySold,
            ),
          )
          .toList(),
    );
  }

  String _readProductName(Map<String, dynamic> row) {
    final products = row['products'];
    if (products is Map<String, dynamic>) {
      final name = products['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return 'Produk tidak dikenal';
  }

  String _readCustomerName(Map<String, dynamic> row) {
    final name = row['customer_name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return _walkInCustomer;
  }

  String _buildLocalInsight({
    required String periodLabel,
    required int totalRevenue,
    required int totalProfit,
    required int transactionCount,
    required int unitsSold,
    required List<ProductSalesSummary> topProducts,
    required List<CustomerSalesSummary> topCustomers,
  }) {
    if (transactionCount == 0) {
      return 'Belum ada penjualan untuk $periodLabel. '
          'Catat transaksi di kasir untuk melihat ringkasan.';
    }

    final buffer = StringBuffer();
    buffer.write(
      'Pada $periodLabel, penjualan Rp ${_formatPlain(totalRevenue)} '
      'dengan laba Rp ${_formatPlain(totalProfit)} '
      'dari $transactionCount transaksi ($unitsSold item).',
    );

    if (topProducts.isNotEmpty) {
      final top = topProducts.first;
      buffer.write(
        ' Produk terlaris: ${top.productName} '
        '(${top.quantitySold} item, laba Rp ${_formatPlain(top.profit)}).',
      );
    }

    if (topCustomers.isNotEmpty) {
      final top = topCustomers.first;
      buffer.write(
        ' Pelanggan utama: ${top.customerName} '
        '(${top.transactionCount} transaksi).',
      );
    }

    return buffer.toString();
  }

  String _formatRangeLabel(DateTime start, DateTime endInclusive) {
    String fmt(DateTime d) {
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return '$day/$month/${d.year}';
    }

    return '${fmt(start)} – ${fmt(endInclusive)}';
  }

  String _formatPlain(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _mapDbError(PostgrestException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('unit_cost') || msg.contains('customer_name') ||
        msg.contains('cost_price')) {
      return 'Kolom laporan belum siap. Push migrasi sales profit/customer ke Supabase.';
    }
    if (msg.contains('relation') && msg.contains('does not exist')) {
      return 'Tabel penjualan belum siap. Pastikan migrasi Supabase sudah diterapkan.';
    }
    if (msg.contains('row-level security') || msg.contains('rls')) {
      return 'Akses laporan ditolak. Pastikan kamu sudah masuk.';
    }
    return 'Terjadi kesalahan saat memuat laporan.';
  }
}

class _MutableAgg {
  _MutableAgg({required this.key, required this.label});

  final String key;
  final String label;
  int revenue = 0;
  int profit = 0;
  int transactionCount = 0;
  int quantitySold = 0;
}
