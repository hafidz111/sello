class DashboardStats {
  const DashboardStats({
    required this.todaySalesTotal,
    required this.todayTransactionCount,
    required this.activeProductCount,
    required this.lowStockCount,
  });

  static const empty = DashboardStats(
    todaySalesTotal: 0,
    todayTransactionCount: 0,
    activeProductCount: 0,
    lowStockCount: 0,
  );

  final int todaySalesTotal;
  final int todayTransactionCount;
  final int activeProductCount;
  final int lowStockCount;
}
