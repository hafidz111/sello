import 'package:sello/models/customer_sales_summary.dart';
import 'package:sello/models/product_sales_summary.dart';
import 'package:sello/models/report_period.dart';

class BusinessReport {
  const BusinessReport({
    required this.period,
    required this.rangeStart,
    required this.rangeEndInclusive,
    required this.totalRevenue,
    required this.totalProfit,
    required this.transactionCount,
    required this.unitsSold,
    required this.topProducts,
    required this.topCustomers,
    required this.insight,
  });

  static BusinessReport empty(ReportPeriod period) {
    final range = ReportDateRange.forPeriod(period);
    return BusinessReport(
      period: period,
      rangeStart: range.start,
      rangeEndInclusive: range.endInclusive,
      totalRevenue: 0,
      totalProfit: 0,
      transactionCount: 0,
      unitsSold: 0,
      topProducts: const [],
      topCustomers: const [],
      insight: 'Belum ada data penjualan untuk periode ini.',
    );
  }

  final ReportPeriod period;
  final DateTime rangeStart;
  final DateTime rangeEndInclusive;
  final int totalRevenue;
  final int totalProfit;
  final int transactionCount;
  final int unitsSold;
  final List<ProductSalesSummary> topProducts;
  final List<CustomerSalesSummary> topCustomers;
  final String insight;

  bool get hasSales => transactionCount > 0;
}
