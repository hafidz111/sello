import 'package:sello/models/sale.dart';

class SalesDaySummary {
  const SalesDaySummary({
    required this.transactionCount,
    required this.totalRevenue,
    required this.totalUnits,
  });

  final int transactionCount;
  final int totalRevenue;
  final int totalUnits;

  static const empty = SalesDaySummary(
    transactionCount: 0,
    totalRevenue: 0,
    totalUnits: 0,
  );
}

class SalesPageResult {
  const SalesPageResult({
    required this.sales,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<Sale> sales;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  bool get hasPrevious => page > 0;

  bool get hasNext => (page + 1) * pageSize < totalCount;

  int get rangeStart => totalCount == 0 ? 0 : page * pageSize + 1;

  int get rangeEnd {
    final end = (page + 1) * pageSize;
    return end > totalCount ? totalCount : end;
  }
}

abstract final class SaleDateRange {
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endExclusive(DateTime date) =>
      startOfDay(date).add(const Duration(days: 1));

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isFutureDay(DateTime date) {
    final today = startOfDay(DateTime.now());
    return startOfDay(date).isAfter(today);
  }

  static String label(DateTime date) {
    final today = DateTime.now();
    if (isSameDay(date, today)) return 'Hari ini';
    final yesterday = today.subtract(const Duration(days: 1));
    if (isSameDay(date, yesterday)) return 'Kemarin';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
