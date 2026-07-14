class CustomerSalesSummary {
  const CustomerSalesSummary({
    required this.customerName,
    required this.revenue,
    required this.profit,
    required this.transactionCount,
    required this.quantitySold,
  });

  final String customerName;
  final int revenue;
  final int profit;
  final int transactionCount;
  final int quantitySold;
}
